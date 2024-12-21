class_name GameManager
extends Node


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
	
	# disables window x button
	get_tree().set_auto_accept_quit(false)
	
	Game.manager = self
	Game.preloader = preloader
	
	var world_seed := randi_range(0, 999999)
	Game.world_seed = world_seed
	seed(world_seed)
	
	Game.server = server
	server.server_disconnected.connect(_on_server_disconected)
	
	var ui: UI = UI.SCENE.instantiate().init()
	
	ui.new_campaign_window.new_campaign_created.connect(_on_new_campaign)
	ui.host_campaign_window.saved_campaign_hosted.connect(_on_host_campaign)
	ui.join_campaign_window.steam_campaign_joined.connect(_on_join_steam_server)
	ui.join_campaign_window.enet_campaign_joined.connect(_on_join_enet_server)
	
	ui.save_campaign_button_pressed.connect(_on_save_campaign)
	ui.reload_campaign_button_pressed.connect(_on_reload_campaign)
	
	ui.scene_tabs.get_tab_bar().tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ALWAYS
	ui.scene_tabs.get_tab_bar().tab_close_pressed.connect(_on_tab_close_pressed)
	ui.scene_tabs.tab_changed.connect(func (_tab: int):
		ui.tab_world.reset()
		ui.tab_builder.reset()
		ui.tab_elements.reset()
		ui.tab_properties.reset()
		ui.tab_settings.reset()
	)
	
	reset()
	
	autosave()
	

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
			"color": Utils.color_to_html_color(new_campaign_data.master_color),
		}
	}
	Utils.dump_json(campaign_path.path_join("campaign.json"), campaign_data, 2)
	
	var map_label := "Untitled"
	var map_slug := Utils.slugify(map_label)
	var map_path := campaign_path.path_join("maps").path_join(map_slug)
	var map_data := {
		"label": map_label
	}
	Utils.dump_json(map_path.path_join("map.json"), map_data, 2)
	
	Utils.make_dirs(campaign_path.path_join("players"))
	Utils.make_dirs(campaign_path.path_join("resources"))
	
	_on_host_campaign(campaign_slug, campaign_data, steam)


func _on_host_campaign(campaign_slug: String, campaign_data: Dictionary, steam: bool) -> void:	
	if Game.server.host_multiplayer(steam):
		Debug.print_error_message("Campaign host failed")
		return
	
	Game.master = Player.new("master", campaign_data.get("master", {"username": "Master"}))
	var campaign := Campaign.new(true, campaign_slug, campaign_data)
	Game.campaign = campaign
	
	Game.ui.tab_world.campaign_selected = campaign
	Game.ui.tab_players.campaign_selected = campaign  # TODO remove
	
	reset()
	
	# whitout this tabs are being duplicated
	await get_tree().process_frame
	
	load_campaign(campaign_data)


func load_campaign(campaign_data: Dictionary):
	var selected_map: String = campaign_data.get("selected_map", "")
	if selected_map not in Game.campaign.maps:
		selected_map = Game.campaign.maps[0]
	
	# open map where players are
	var players_map: String = campaign_data.get("players_map", "")
	if players_map not in Game.campaign.maps:
		players_map = selected_map
		
	TabScene.SCENE.instantiate().init(players_map, Game.campaign.get_map_data(players_map))
	
	# open map where mastes is (if different)
	if players_map != selected_map:
		TabScene.SCENE.instantiate().init(selected_map, Game.campaign.get_map_data(selected_map))
		Game.ui.scene_tabs.current_tab = 1
		
	Game.ui.tab_world.players_map = players_map
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
	Game.flow.change_flow_state(campaign_data.get("state", 0))


func _on_reload_campaign():
	save_campaign()
	if not Game.campaign:
		return
	if Game.campaign.is_master:
		_on_host_campaign(Game.campaign.slug, Game.campaign.json(), Game.server.is_steam_game)
	elif Game.server.is_steam_game:
		_on_join_steam_server(Game.server.lobby_id)
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


func _on_join_steam_server(lobby_id: int):
	Game.server.join_steam_multiplayer(lobby_id)


func _on_join_enet_server(host: String, username: String, password: String):
	Game.server.join_enet_multiplayer(host, username, password)


func _on_server_disconected():
	Game.campaign = null
	reset()


func _on_tab_close_pressed(tab_index: int):
	var tab_scene: TabScene = Game.ui.scene_tabs.get_tab_control(tab_index)
	var map := tab_scene.map
	
	if map.slug == Game.ui.tab_world.players_map:
		Utils.temp_tooltip("Player's map cannot be close. Send them to another map")
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
	
	# restart the frame input handled
	Game.handled_input = false


#func _physics_process(delta: float) -> void:
	#Game.handled_input = false


func reset():
	Game.resources.clear()
	Game.maps.clear()
	
	for tab_scene in Game.ui.scene_tabs.get_children():
		tab_scene.queue_free()
	
	Game.ui.tab_elements.reset()
	Game.ui.tab_jukebox.reset()
	Game.ui.tab_builder.reset()
	Game.ui.tab_resources.reset()
	Game.ui.tab_properties.reset()
	Game.ui.tab_messages.reset()
	
	Game.flow.change_flow_state(FlowController.STATE.PLAYING)
	
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
		return  # TODO return a default resource
	
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
	save_campaign()
	get_tree().quit()


#########
# input #
#########

func _input(event):
	if event is InputEventKey:
		if event.is_pressed():
			if multiplayer.multiplayer_peer and multiplayer.is_server():
				if event.keycode == KEY_F4:
					if DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED:
						DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
					else:
						DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
						
				if event.keycode == KEY_F5:
					if Game.server.peer:
						Game.server.peer.close()
						Game.server.peer = null
					get_tree().reload_current_scene()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		safe_quit()
