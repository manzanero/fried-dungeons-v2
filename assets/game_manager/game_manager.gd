class_name GameManager
extends Node


const UI_SCENE := preload("res://ui/ui.tscn")
const TAB_SCENE := preload("res://ui/tabs/tab_scene/tab_scene.tscn")


@onready var server: Node = $ServerManager
@onready var preloader: ResourcePreloader = $ResourcePreloader


func _ready() -> void:
	DebugMenu.style = DebugMenu.Style.HIDDEN
	#DebugMenu.style = DebugMenu.Style.VISIBLE_COMPACT
	#DebugMenu.style = DebugMenu.Style.VISIBLE_DETAILED
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	#DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	# disables window x button
	get_tree().set_auto_accept_quit(false)
	
	Game.manager = self
	Game.server = server
	Game.server.server_disconnected.connect(_on_server_disconected)
	Game.preloader = preloader
	
	var world_seed := randi_range(0, 999999)
	Game.world_seed = world_seed
	seed(world_seed)
	
	var ui := UI_SCENE.instantiate()
	Game.ui = ui
	add_child(ui)
	ui.ide.visible = false
	ui.main_menu.visible = true
	ui.save_campaign_button_pressed.connect(save_campaign)
	ui.main_menu.host_campaign_pressed.connect(_on_host_campaign_pressed)
	ui.main_menu.join_server_pressed.connect(_on_join_server_pressed)
	
	ui.reload_campaign_pressed.connect(_on_reload_campaign_pressed)
	ui.scene_tabs.get_tab_bar().tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ALWAYS
	ui.scene_tabs.get_tab_bar().tab_close_pressed.connect(_on_tab_close_pressed)
	ui.scene_tabs.tab_changed.connect(func (_tab: int):
		ui.tab_world.reset()
		ui.tab_builder.reset()
		ui.tab_elements.reset()
		ui.tab_properties.reset()
		ui.tab_settings.reset()
	)
	
	Game.flow = ui.flow_controller


func save_campaign():
	if not Game.campaign or not Game.campaign.is_master:
		return
		
	var campaign := Game.campaign; 
	if not campaign: 
		return

	Utils.make_dirs(campaign.maps_path)
	for map_slug in Game.maps:
		var map: Map = Game.maps[map_slug] 
		save_map(map)
		
	var campaign_data := campaign.json()
	
	Utils.dump_json(campaign.campaign_path.path_join("campaign.json"), campaign_data, 2)
	
	Debug.print_info_message("Campaign \"%s\" saved" % Game.campaign.slug)
	
	Game.ui.tab_world.scan(campaign)
	Game.ui.tab_world.refresh_tree()


func save_map(map: Map):
	var map_path := Game.campaign.maps_path.path_join(map.slug)
	var map_data := map.json()
	Utils.make_dirs(map_path)
	Utils.dump_json(map_path.path_join("map.json"), map_data)
	
	var old_slug := map.slug
	var new_slug := Utils.slugify(map.label)
	if old_slug != new_slug:
		Game.maps[new_slug] = map
		Game.maps.erase(old_slug)
		map.slug = new_slug
		var map_new_path := Game.campaign.maps_path.path_join(new_slug)
		Utils.rename(map_path, map_new_path)


func _on_reload_campaign_pressed():
	if Game.campaign and Game.campaign.is_master:
		_on_host_campaign_pressed(Game.campaign.slug)
	else:
		var main_menu := Game.ui.main_menu
		_on_join_server_pressed(
				main_menu.host_line_edit.text, 
				main_menu.username_line_edit.text, 
				main_menu.password_line_edit.text)


func _on_host_campaign_pressed(campaign_slug: String):
	var campaign_path := "user://campaigns".path_join(campaign_slug).path_join("campaign.json")
	var campaign_data := Utils.load_json(campaign_path)
	
	if Game.server.host_multiplayer():
		return
		
	var campaign := Campaign.new(true, campaign_data.label, campaign_data.get("imports", {}))
	Game.campaign = campaign
	
	Game.ui.ide.visible = true
	Game.ui.main_menu.visible = false
	
	Game.ui.tab_world.campaign_selected = campaign
	Game.ui.tab_players.campaign_selected = campaign
	
	set_profile(true)
	reset()
	
	await get_tree().process_frame
	
	var selected_map: String = campaign_data.selected_map
	if selected_map not in campaign.maps:
		selected_map = campaign.maps[0]
		
	var players_map: String = campaign_data.players_map
	if players_map not in campaign.maps:
		players_map = selected_map
		 
	TAB_SCENE.instantiate().init(players_map, campaign.get_map_data(players_map))

	if players_map != selected_map:
		TAB_SCENE.instantiate().init(selected_map, campaign.get_map_data(selected_map))
		Game.ui.scene_tabs.current_tab = 1
		
	Game.ui.tab_world.players_map = players_map
	Game.ui.tab_world.selected_map = selected_map
	Game.ui.tab_world.refresh_tree()
	
	# init jukebox
	for sound_data in campaign_data.get("jukebox", {}).get("sounds", []):
		var sound := get_resource(CampaignResource.Type.SOUND, sound_data.sound)
		if sound:
			Game.ui.tab_jukebox.add_sound(sound, sound_data.loop, sound_data.get("position", 0.0))
		

func _on_join_server_pressed(host: String, username: String, password: String):
	if Game.server.join_multiplayer(host, username, password):
		return
		
	Game.ui.ide.visible = true
	Game.ui.main_menu.visible = false
	set_profile(false)


func _on_server_disconected():
	Game.ui.ide.visible = false
	Game.ui.main_menu.visible = true


func _on_tab_close_pressed(tab_index: int):
	var tab_scene: TabScene = Game.ui.scene_tabs.get_tab_control(tab_index)
	var map := tab_scene.map
	
	if map.slug == Game.ui.tab_world.players_map:
		Utils.temp_tooltip("Player's map cannot be close. Send them to another map")
		return
	
	save_map(map)
	Game.maps.erase(map.slug)
	tab_scene.queue_free()
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
	if is_instance_valid(Game.ui.main_menu.campaign_buttons_group):
		Utils.reset_button_group(Game.ui.main_menu.campaign_buttons_group)
	if is_instance_valid(Game.ui.main_menu.server_buttons_group):
		Utils.reset_button_group(Game.ui.main_menu.server_buttons_group)
	
	Game.ui.tab_elements.reset()
	Game.ui.tab_jukebox.reset()
	Game.ui.tab_builder.reset()
	Game.ui.tab_instancer.reset()
	Game.ui.tab_properties.reset()
	Game.ui.tab_messages.reset()
	
	Game.maps.clear()
	for tab_scene in Game.ui.scene_tabs.get_children():
		tab_scene.queue_free()
	
	Game.flow.change_flow_state(FlowController.STATE.PLAYING)
	
	await get_tree().process_frame


func set_profile(is_master: bool):
	Game.ui.nav_campaing.set_item_disabled(0, not is_master)
	Game.ui.scene_coverings.offset_top = 29 if is_master else 4
	Game.ui.flow_controller.player_blocker.visible = not is_master
	Game.ui.left.visible = is_master
	Game.ui.middle_down.visible = is_master
	Game.ui.right_up.visible = is_master
	Game.ui.scene_tabs.tabs_visible = is_master
	Game.ui.right_down.tabs_visible = is_master


func get_resource(resource_type, resource_path) -> CampaignResource:
	var resources := Game.ui.tab_instancer.resources
	var resource: CampaignResource = resources.get(resource_path)
	if resource:
		return resource
		
	if Game.campaign.is_master:
		return
	
	# create a temporally empty resource
	var import_data = Game.campaign.imports.get(resource_path, {})
	resource = CampaignResource.new(resource_type, resource_path, import_data)
	resources[resource_path] = resource
	
	# request the resource if not binary
	if FileAccess.file_exists(resource.abspath):
		resource.loaded = true
	else:
		Game.server.request_resource.rpc_id(1, resource_path)
	
	return resource


func set_resource(resource_type, resource_path, import_data) -> void:
	var resource := get_resource(resource_type, resource_path)
	resource.import_data = import_data


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
