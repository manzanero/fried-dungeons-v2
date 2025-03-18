class_name GameManager
extends Node


signal campaign_loaded
signal map_loaded(slug: String)

const UI_SCENE := preload("res://ui/ui.tscn")
const TAB_SCENE := preload("res://ui/tabs/tab_scene/tab_scene.tscn")
const HOME_ANIMATION = preload("res://ui/home_animation/home_animation.tscn")

const PLAY_SCENE_ICON := preload("res://resources/icons/play_scene_icon.png")
const SCENE_ICON := preload("res://resources/icons/scene_icon.png")

@onready var server: Node = $ServerManager
@onready var preloader: ResourcePreloader = $ResourcePreloader


func _ready() -> void:
	DebugMenu.style = DebugMenu.Style.HIDDEN
	#DebugMenu.style = DebugMenu.Style.VISIBLE_COMPACT
	#DebugMenu.style = DebugMenu.Style.VISIBLE_DETAILED
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	#DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	# workarround to lose focus of the window on the first click of the window
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
	
	get_window().min_size = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"), 
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)
	
	# disables window x button
	get_tree().set_auto_accept_quit(false)
	
	Game.manager = self
	Game.preloader = preloader
	
	var world_seed := randi_range(0, 999999)
	Game.world_seed = world_seed
	seed(world_seed)
	
	Game.server = server
	server.server_disconnected.connect(_on_server_disconected)
	
	var ui: UI = UI_SCENE.instantiate().init()
	
	ui.new_campaign_window.new_campaign_created.connect(_on_new_campaign)
	ui.host_campaign_window.saved_campaign_hosted.connect(_on_host_campaign)
	ui.join_campaign_window.steam_campaign_joined.connect(_on_join_steam_server)
	ui.join_campaign_window.enet_campaign_joined.connect(_on_join_enet_server)
	
	ui.save_campaign_button_pressed.connect(_on_save_campaign)
	ui.reload_campaign_button_pressed.connect(_on_reload_campaign)
	
	#ui.scene_tabs.get_tab_bar().tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ALWAYS
	ui.scene_tabs.get_tab_bar().add_theme_stylebox_override("button_highlight", StyleBoxEmpty.new())
	ui.scene_tabs.get_tab_bar().add_theme_stylebox_override("button_pressed", StyleBoxEmpty.new())
	ui.scene_tabs.get_tab_bar().tab_close_pressed.connect(_on_tab_close_pressed)
	ui.scene_tabs.tab_changed.connect(_on_tab_changed)
	ui.scene_tabs.child_order_changed.connect(refresh_tabs)
	
	#var home_animation: HomeAnimation = HOME_ANIMATION.instantiate()
	#Game.manager.add_child(home_animation)
	#campaign_loaded.connect(func (): ui.app_music.stop())
	
	reset()
	
	autosave()
	
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	
	# audio preferences
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"), linear_to_db(Game.audio_preferences.master_volume))
	if Game.audio_preferences.app_music:
		Game.ui.app_music.play()
	Game.ui.nav_bar.master_volume_controller.set_scene_volume(
		not Game.audio_preferences.scene_sounds, Game.audio_preferences.scene_volume)
	
	# video preferences
	var monitor := Game.video_preferences.start_on_monitor
	monitor = clampi(monitor, 0, DisplayServer.get_screen_count())
	if monitor:
		var window_size := DisplayServer.window_get_size()
		var screen_size := DisplayServer.screen_get_size(monitor)
		var screen_position := DisplayServer.screen_get_position(monitor)
		var window_position_x := screen_size.x / 2.0 - window_size.x / 2.0 + screen_position.x
		var window_position_y := screen_size.y / 2.0 - window_size.y / 2.0 + screen_position.y
		DisplayServer.window_set_current_screen(monitor)
		DisplayServer.window_set_position(Vector2(window_position_x, window_position_y))
	if Game.video_preferences.start_maximized:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

	
func _on_tab_changed(tab: int):
	Game.ui.tab_world.reset()
	Game.ui.tab_builder.reset()
	Game.ui.tab_elements.reset()
	Game.ui.tab_properties.reset()
	Game.ui.tab_properties.settings.reset()
	
	Game.modes.reset()
	Game.ui.build_border.visible = false
	
	var map := Game.ui.selected_map
	if map and map.selected_level:
		map.current_ambient_light = map.ambient_light
		map.current_ambient_color = map.ambient_color
		if Game.campaign.is_master:
			if map.override_ambient_light:
				map.current_ambient_light = map.master_ambient_light
			if map.override_ambient_color:
				map.current_ambient_color = map.master_ambient_color
		
		map.selected_level.change_state(Level.State.GO_IDLE)
		if Game.master_is_player:
			map.selected_level.set_control(Game.master_is_player.elements)
			map.is_master_view = false
		elif Game.player_is_master:
			map.selected_level.set_master_control()
			map.is_master_view = true
		else:
			map.selected_level.set_control(Game.player.elements)
			map.is_master_view = false

		if Game.ui.selected_scene_tab.fade_transition._current_tween:
			Game.ui.selected_scene_tab.fade_transition._current_tween.kill()
		Game.ui.selected_scene_tab.fade_transition.cover(0)
		get_tree().create_timer(0.2).timeout.connect(func ():
			Game.ui.selected_scene_tab.fade_transition.uncover(1)
		)

		for level: Level in map.levels.values():
			level.refresh_light()
	
	# disable process in hidden and non players tab
	for i in Game.ui.scene_tabs.get_tab_count():
		var tab_scene: TabScene = Game.ui.scene_tabs.get_tab_control(i)
		var players_map := Game.ui.tab_world.players_map
		if i == tab or players_map == tab_scene.map.slug:
			tab_scene.process_mode = PROCESS_MODE_ALWAYS
		else:
			tab_scene.process_mode = PROCESS_MODE_DISABLED
		
	refresh_tabs()
	
	if Game.ui.selected_map:
		Game.flow.players_in_scene = Game.ui.selected_map.slug == Game.ui.tab_world.players_map


func refresh_tabs():
	Game.maps.clear()
	for i in Game.ui.scene_tabs.get_tab_count():
		var tab_scene: TabScene = Game.ui.scene_tabs.get_tab_control(i)
		var map := tab_scene.map
		Game.maps[map.slug] = map
		
		var players_map := Game.ui.tab_world.players_map
		if players_map == tab_scene.map.slug:
			Game.ui.scene_tabs.get_tab_bar().set_tab_icon(i, PLAY_SCENE_ICON)
		else:
			Game.ui.scene_tabs.get_tab_bar().set_tab_icon(i, SCENE_ICON)


func _on_new_campaign(new_campaign_data: Dictionary, steam: bool) -> void:
	var campaign_label: String = new_campaign_data.title
	if not campaign_label:
		Debug.print_error_message("Campaign label is empty")
		return
		
	var campaign_slug := Utils.slugify(campaign_label)
	var campaign_path := "user://campaigns".path_join(campaign_slug)
	var campaign_data := {
		"label": campaign_label,
		"master": {
			"username": new_campaign_data.master_name,
			"color": Utils.color_no_alpha(Utils.color_to_html_color(new_campaign_data.master_color)),
		},
		"state": 1,
	}
	if new_campaign_data.get("example_resources"):
		campaign_data["jukebox"] = {}
		campaign_data["jukebox"]["music"] = {}
		campaign_data["jukebox"]["music"]["Fried Dungeons Theme"] = {}
		campaign_data["jukebox"]["music"]["Fried Dungeons Theme"]["resource"] = "Fried Dungeons Theme.mp3"
	Utils.dump_json(campaign_path.path_join("campaign.json"), campaign_data, 2)
	
	var map_label := "Untitled"
	var map_slug := Utils.slugify(map_label)
	var map_path := campaign_path.path_join("maps").path_join(map_slug)
	var map_data := {
		"label": map_label
	}
	
	# master chooses init resources
	if new_campaign_data.get("example_resources"):
		map_data["settings"] = {}
		map_data["settings"]["atlas_texture"] = "texture_atlas.png"
	Utils.dump_json(map_path.path_join("map.json"), map_data, 2)
	
	Utils.make_dirs(campaign_path.path_join("players"))
	Utils.make_dirs(campaign_path.path_join("resources"))
	
	if new_campaign_data.get("example_resources"):
		for files in [
			["./init_resources/heroes.png", campaign_path.path_join("resources").path_join("heroes.png")],
			["./init_resources/heroes.png.json", campaign_path.path_join("resources").path_join("heroes.png.json")],
			["./init_resources/texture_atlas.png", campaign_path.path_join("resources").path_join("texture_atlas.png")],
			["./init_resources/texture_atlas.png.json", campaign_path.path_join("resources").path_join("texture_atlas.png.json")],
			["./init_resources/music/FRIED-DUNGEONS_MAIN-v01_PRE.mp3", campaign_path.path_join("resources").path_join("Fried Dungeons Theme.mp3")],
		]:
			Utils.copy(files[0], files[1])
	
	_on_host_campaign(campaign_slug, campaign_data, steam)


func _on_host_campaign(campaign_slug: String, campaign_data: Dictionary, steam: bool) -> void:	
	if Game.server.host_multiplayer(steam):
		Debug.print_error_message("Campaign host failed")
		return
	
	Game.master = Player.new("master", campaign_data.get("master", {"username": "Master"}))
	Game.player = null
	var campaign := Campaign.new(true, campaign_slug, campaign_data)
	Game.campaign = campaign
	
	Game.ui.tab_world.campaign_selected = campaign
	
	reset()
	
	# whitout this tabs are being duplicated
	await get_tree().process_frame
	
	load_campaign(campaign_data)


func load_campaign(campaign_data: Dictionary):
	var selected_map_slug: String = campaign_data.get("selected_map", "")
	if selected_map_slug not in Game.campaign.maps:
		selected_map_slug = Game.campaign.maps[0]
	
	# open map where players are
	var players_map_slug: String = campaign_data.get("players_map", "")
	if players_map_slug not in Game.campaign.maps:
		players_map_slug = selected_map_slug
	
	var players_map_data := Game.campaign.get_map_data(players_map_slug)
	var players_map_tab: TabScene = TAB_SCENE.instantiate().init(players_map_slug, players_map_data, true)
	map_loaded.emit(players_map_tab.map.slug)
	
	Game.ui.tab_world.players_map = players_map_slug
	Game.flow.players_in_scene = true
	
	# open map where master is (if different)
	if players_map_slug != selected_map_slug:
		var selected_map_data := Game.campaign.get_map_data(selected_map_slug)
		var selected_map_tab: TabScene = TAB_SCENE.instantiate().init(selected_map_slug, selected_map_data)
		map_loaded.emit(selected_map_tab.map.slug)
		Game.ui.scene_tabs.current_tab = 1
		Game.flow.players_in_scene = false
		
	Game.ui.tab_world.refresh_tree()
	
	# init jukebox
	var jukebox_data: Dictionary = campaign_data.get("jukebox") if campaign_data.get("jukebox") is Dictionary else {}
	var music_paths: Dictionary = jukebox_data.get("music") if jukebox_data.get("music") is Dictionary else {}
	for music_path: String in music_paths:
		var music_data: Dictionary = music_paths[music_path]
		var music_resoure_path: String = music_data.get("resource", "")
		if not music_resoure_path:
			continue
		var sound := get_resource(CampaignResource.Type.SOUND, music_resoure_path)
		if not sound:
			continue
		Game.ui.tab_jukebox.add_sound(sound, music_data.get("position", 0.0))
	
	Game.ui.tab_jukebox.muted = jukebox_data.get("muted", false)
	
	# state
	Game.flow.change_flow_state(campaign_data.get("state", 1))
	
	campaign_loaded.emit()


func _on_reload_campaign():
	save_campaign()
	if not Game.campaign:
		return
	if Game.campaign.is_master:
		_on_host_campaign(Game.campaign.slug, Game.campaign.json(), Game.server.is_steam_game)
	elif Game.server.is_steam_game:
		_on_join_steam_server(Game.server.lobby_id, Game.server.steam_user)
	else:
		_on_join_enet_server(Game.server.enet_host, Game.server.enet_username, Game.server.enet_password)


func _on_save_campaign():
	save_campaign()
	

func autosave():
	get_tree().create_timer(60).timeout.connect(autosave)
	save_campaign()


func save_campaign():
	if not Game.campaign or not Game.campaign.is_master:
		return

	for map in Game.maps.values():
		save_map(map)
	
	Game.campaign.save_campaign_data()
	Game.ui.tab_world.reset()
	
	Debug.print_info_message("Campaign \"%s\" saved" % Game.campaign.slug)


func save_map(map: Map):
	Game.campaign.set_map_data(map.slug, map.json())
	
	# check if the slug changes
	var old_slug := map.slug
	var new_slug := Utils.slugify(map.label)
	if map.slug != new_slug:
		Utils.rename(Game.campaign.get_map_path(old_slug), Game.campaign.get_map_path(new_slug))
		Game.maps.erase(old_slug)
		Game.maps[new_slug] = map
		map.slug = new_slug
		
		Game.server.rpcs.change_map_slug.rpc(old_slug, new_slug)
		
	
	Debug.print_info_message("Map \"%s\" saved" % map.slug)


func _on_join_steam_server(lobby_id: int, username: String):
	Game.server.join_steam_multiplayer(lobby_id, username)


func _on_join_enet_server(host: String, username: String, password: String):
	Game.server.join_enet_multiplayer(host, username, password)


func _on_server_disconected():
	Game.campaign = null
	Game.ui.tab_jukebox.reset()
	#Game.ui.flow_border.visible = false
	reset()


func _on_tab_close_pressed(tab_index: int):
	var tab_scene: TabScene = Game.ui.scene_tabs.get_tab_control(tab_index)
	var map := tab_scene.map
	
	if map.slug == Game.ui.tab_world.players_map:
		Utils.temp_error_tooltip("Players's map cannot be close. Send them to another map")
		return
	
	save_map(map)
	Game.maps.erase(map.slug)
	tab_scene.queue_free()
	
	# wait tab to close
	await get_tree().process_frame
	
	Game.ui.tab_world.scan(Game.campaign)
	Game.ui.tab_world.refresh_tree()


func _process(_delta: float) -> void:
	Game.radian_friendly_tick = floor(Time.get_ticks_msec() / (2 * PI) / 32)
	Game.wave_global = sin(Game.radian_friendly_tick)
	Game.process_frame = Engine.get_process_frames()
	Game.ticks_msec = Time.get_ticks_msec()
	Game.control_with_focus = get_viewport().gui_get_focus_owner()
	Game.control_uses_keyboard = false
	if Game.control_with_focus is LineEdit:
		Game.control_uses_keyboard = true
	elif Game.control_with_focus is Tree:
		Game.control_uses_keyboard = true
	elif Game.control_with_focus is TextEdit:
		Game.control_uses_keyboard = true
	
	# restart the frame input handled
	Game.handled_input = false


func reset():
	Game.blueprints.clear()
	Game.resources.clear()
	Game.maps.clear()
	
	for tab_scene in Game.ui.scene_tabs.get_children():
		tab_scene.queue_free()
	
	Game.ui.tab_elements.reset()
	Game.ui.tab_players.reset()
	Game.ui.tab_jukebox.reset()
	Game.ui.tab_builder.reset()
	Game.ui.tab_resources.reset()
	Game.ui.tab_blueprints.reset()
	Game.ui.tab_properties.reset()
	Game.ui.tab_messages.reset()
	
	set_profile()
	
	# wait to clean scene tabs
	await get_tree().process_frame


func set_profile():
	if Game.campaign:
		var is_master := Game.campaign.is_master
		Game.ui.scene_coverings.offset_top = 29 if is_master else 4
		Game.ui.left.visible = is_master
		Game.ui.middle_down.visible = is_master
		Game.ui.right_up.visible = is_master
		Game.ui.scene_tabs.tabs_visible = is_master
		Game.ui.ide.visible = true
		Game.modes.visible = is_master
	else:
		Game.ui.ide.visible = false

	Game.ui.nav_bar.set_profile()


func get_resource(resource_type: String, resource_path: String) -> CampaignResource:
	if resource_path == "":
		return
	var resource: CampaignResource = Game.resources.get(resource_path)
	if resource:
		return resource
	
	resource = update_resource(resource_type, resource_path)
	return resource


func update_resource(resource_type: String, resource_path: String) -> CampaignResource:
	if Game.campaign.is_master: 
		return
	
	# get or create
	var resource: CampaignResource = Game.resources.get(resource_path)
	if not resource:
		resource = CampaignResource.new(resource_type, resource_path)
		Game.resources[resource_path] = resource
	
	return resource.update()


func set_resource(resource_type: String, resource_path: String, resource_data: Dictionary) -> void:
	var resource := get_resource(resource_type, resource_path)
	var resource_updated := false
	if resource.timestamp != resource_data.timestamp:
		resource.timestamp = resource_data.timestamp
		resource_updated = true
	if resource.resource_import_as != resource_data.import_as:
		resource.resource_import_as = resource_data.import_as
		resource_updated = true
	if str(resource.attributes) != str(resource_data.attributes):
		resource.attributes = resource_data.attributes
		resource_updated = true
	if resource_updated:
		Game.campaign.set_resource_data(resource.path, resource.json())


func remove_resource(resource_path: String) -> void:
	var resource: CampaignResource = Game.resources.get(resource_path)
	if resource:
		resource.remove()


func safe_quit():
	if Game.campaign:
		Game.ui.exit_window.visible = true
		Game.ui.exit_window.exit_type = "Fried Dungeons"
		var response = await Game.ui.exit_window.response
		if response:
			save_campaign()
			get_tree().quit()
	else:
		save_campaign()
		get_tree().quit()
	

func _on_focus_changed(control: Control) -> void:
	Debug.print_debug_message(str(control.name) if control else "None")


#########
# input #
#########

func _input(event):
	if event is InputEventKey:
		if event.is_pressed():
			#if multiplayer.multiplayer_peer and multiplayer.is_server():
				if event.keycode == KEY_F4:
					if DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED:
						DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
					else:
						DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
						
				#if event.keycode == KEY_F5:
					#if Game.server.peer:
						#Game.server.peer.close()
						#Game.server.peer = null
					#get_tree().reload_current_scene()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		safe_quit()
