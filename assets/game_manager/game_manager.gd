extends Node

const UI_SCENE := preload("res://ui/ui.tscn")
const TAB_MAP := preload("res://ui/tabs/tab_map/tab_map.tscn")


@onready var server: Node = $ServerManager


func _ready() -> void:
	#DebugMenu.style = DebugMenu.Style.HIDDEN
	DebugMenu.style = DebugMenu.Style.VISIBLE_COMPACT
	#DebugMenu.style = DebugMenu.Style.VISIBLE_DETAILED
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	#DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	# disables window x button
	get_tree().set_auto_accept_quit(false)
	
	Game.server = server
	
	Game.ui = UI_SCENE.instantiate()
	add_child(Game.ui)
	Game.ui.ide.visible = false
	Game.ui.main_menu.visible = true
	Game.ui.save_campaign_button_pressed.connect(_on_save_campaign_button_pressed)
	Game.ui.main_menu.host_campaign_pressed.connect(_on_host_campaign_pressed)
	Game.ui.main_menu.join_campaign_pressed.connect(_on_join_campaign_pressed)
	
	Game.ui.reload_campaign_pressed.connect(_on_reload_campaign_pressed)
	Game.ui.map_tabs.tab_changed.connect(Game.ui.tab_builder.reset.unbind(1))
	Game.ui.map_tabs.get_tab_bar().tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ALWAYS
	Game.ui.map_tabs.get_tab_bar().tab_close_pressed.connect(_on_tab_close_pressed)
	
	
func _on_save_campaign_button_pressed():
	var campaign := Game.campaign
	
	var opened_maps := []
	Utils.make_dirs(campaign.maps_path)
	for map: Map in Game.ui.opened_maps:
		opened_maps.append(map.slug)
		save_map(map)
	
	var campaign_data := {
		"label": campaign.label,
		"opened_maps": opened_maps,
		"selected_map": Game.ui.selected_map.slug,
		"players": campaign.players,
	}
	
	Utils.dump_json("%s/campaign.json" % campaign.campaign_path, campaign_data)
	
	Game.ui.tab_world.scan(campaign)
	Game.ui.tab_world.refresh_tree()
	

func save_map(map: Map):
	var map_path := Game.campaign.maps_path.path_join(map.slug)
	var map_data := map.json()
	Utils.make_dirs(map_path)
	Utils.dump_json(map_path.path_join("map.json"), map_data)
	
	var map_new_slug := Utils.slugify(map.label)
	if map.slug != map_new_slug:
		map.slug = map_new_slug
		var map_new_path := Game.campaign.maps_path.path_join(map_new_slug)
		Utils.rename(map_path, map_new_path)


func _on_reload_campaign_pressed():
	_on_host_campaign_pressed(Game.campaign)
	
	
func _on_host_campaign_pressed(campaign: Campaign):
	Game.ui.ide.visible = true
	Game.ui.main_menu.visible = false
	reset()
	
	Game.player_is_master = true
	Game.campaign = campaign
	Game.ui.tab_world.campaign_selected = campaign
	var campaign_slug := campaign.slug
	var campaign_path := "user://campaigns/%s/campaign.json" % [campaign_slug]
	var campaign_data := Utils.load_json(campaign_path)
	
	var selected_map: String = campaign.maps[0]
	if campaign_data.has("selected_map"):
		selected_map = campaign_data.selected_map
		
	var map_path := "user://campaigns/%s/maps/%s/map.json" % [campaign_slug, selected_map]
	var map_data := Utils.load_json(map_path)
	if not map_data.has("label"):
		selected_map = campaign.maps[0]
		map_path = "user://campaigns/%s/maps/%s/map.json" % [campaign_slug, selected_map]
		map_data = Utils.load_json(map_path)
	
	await get_tree().process_frame
	var tab_map: TabMap = TAB_MAP.instantiate().init(selected_map, map_data)
	Game.ui.tab_world.refresh_tree()
	
	tab_map.map.camera.target_position.position = Utils.v2i_to_v3(tab_map.map.selected_level.rect.get_center())
	tab_map.map.camera.fps_enabled.connect(_on_camera_fps_enabled)


func _on_join_campaign_pressed():
	pass

func _on_tab_close_pressed(tab_index: int):
	var tab_map: TabMap = Game.ui.map_tabs.get_tab_control(tab_index)
	var map := tab_map.map
	save_map(map)
	tab_map.queue_free()
	await get_tree().process_frame
	Game.ui.tab_world.scan(Game.campaign)
	Game.ui.tab_world.refresh_tree()


func _on_camera_fps_enabled(value: bool):
	if value:
		var light := Game.ui.tab_settings.ambient_light_spin.value / 100.0
		var color := Game.ui.tab_settings.ambient_color_button.color
		Game.ui.tab_settings.ambient_changed.emit(true, light, color)
	else:
		Game.ui.tab_settings.master_view_check.pressed.emit()
	
	var builder_button_pressed = Game.ui.tab_builder.wall_button.button_group.get_pressed_button()
	if builder_button_pressed:
		var state_machine := Game.ui.selected_map.selected_level.state_machine
		state_machine.change_state("Idle")
		builder_button_pressed.button_pressed = false
	
	get_tree().set_group("lights", "hidden", value)
	get_tree().set_group("base", "visible", not value)
	
	
func _process(_delta: float) -> void:
	Game.radian_friendly_tick = floor(Time.get_ticks_msec() / (2 * PI) / 32)
	Game.wave_global = sin(Game.radian_friendly_tick)
	
	# restart the frame input handled
	Game.handled_input = false


func reset():
	var campaign_button_pressed = Game.ui.main_menu.campaign_buttons_group.get_pressed_button()
	if campaign_button_pressed:
		campaign_button_pressed.button_pressed = false
	var server_button_pressed = Game.ui.main_menu.server_buttons_group.get_pressed_button()
	if server_button_pressed:
		server_button_pressed.button_pressed = false
	
	Game.ui.tab_builder.reset()
	Game.ui.tab_properties.element_selected = null
	for tab_map in Game.ui.map_tabs.get_children():
		tab_map.queue_free()
	
	await get_tree().process_frame


func safe_quit():
	_on_save_campaign_button_pressed()
	get_tree().quit()


#########
# input #
#########

func _input(event):
	if event is InputEventKey:
		if event.is_pressed():
			if event.keycode == KEY_F4:
				if DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
				else:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
					
			if event.keycode == KEY_F5:
				get_tree().reload_current_scene()
				
				
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		safe_quit()
