class_name GameManager
extends Node

const UI_SCENE := preload("res://ui/ui.tscn")
const TAB_SCENE := preload("res://ui/tabs/tab_scene/tab_scene.tscn")


@onready var server: Node = $ServerManager


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
	
	Game.world_seed = randi_range(0, 999999)
	seed(Game.world_seed)
	
	Game.ui = UI_SCENE.instantiate()
	add_child(Game.ui)
	Game.ui.ide.visible = false
	Game.ui.main_menu.visible = true
	Game.ui.save_campaign_button_pressed.connect(_on_save_campaign_button_pressed)
	Game.ui.main_menu.host_campaign_pressed.connect(_on_host_campaign_pressed)
	Game.ui.main_menu.join_server_pressed.connect(_on_join_server_pressed)
	
	Game.ui.reload_campaign_pressed.connect(_on_reload_campaign_pressed)
	Game.ui.scene_tabs.tab_changed.connect(func (_tab: int):
		Game.ui.tab_builder.reset()
		Game.ui.tab_elements.reset()
		Game.ui.tab_settings.reset()
	)
	Game.ui.scene_tabs.get_tab_bar().tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ALWAYS
	Game.ui.scene_tabs.get_tab_bar().tab_close_pressed.connect(_on_tab_close_pressed)
	
	Game.maps.clear()

	
func _on_save_campaign_button_pressed():
	if multiplayer.is_server():
		var campaign := Game.campaign; if not campaign: return
		#var opened_maps := []
		Utils.make_dirs(campaign.maps_path)
		for map: Map in Game.ui.opened_maps:
			#opened_maps.append(map.slug)
			save_map(map)
		
		var campaign_data := {
			"label": campaign.label,
			#"opened_maps": opened_maps,
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
	
	var old_slug := map.slug
	var new_slug := Utils.slugify(map.label)
	if old_slug != new_slug:
		Game.maps[new_slug] = map
		Game.maps.erase(old_slug)
		map.slug = new_slug
		var map_new_path := Game.campaign.maps_path.path_join(new_slug)
		Utils.rename(map_path, map_new_path)
	

func _on_reload_campaign_pressed():
	_on_host_campaign_pressed(Game.campaign)
	
	
func _on_host_campaign_pressed(campaign: Campaign):
	Game.ui.ide.visible = true
	Game.ui.main_menu.visible = false
	reset()
	
	Game.ui.tab_world.campaign_selected = campaign
	Game.ui.tab_players.campaign_selected = campaign
	var campaign_data := Utils.load_json(campaign.campaign_path.path_join("campaign.json"))
	
	# Get map to open
	var selected_map: String = campaign.maps[0]
	if campaign_data.has("selected_map"):
		selected_map = campaign_data.selected_map
	var map_data := Utils.load_json(campaign.maps_path.path_join(selected_map).path_join("map.json"))
	if not map_data.has("label"):
		selected_map = campaign.maps[0]
		map_data = Utils.load_json(campaign.maps_path.path_join(selected_map).path_join("map.json"))
	
	await get_tree().process_frame
	
	var _tab_scene: TabScene = TAB_SCENE.instantiate().init(selected_map, map_data)
	Game.ui.tab_world.refresh_tree()
	
	set_profile()
	
	Game.ui.tab_resources.reset()


func _on_join_server_pressed(server_data: Dictionary):
	if Game.server.join_multiplayer(server_data):
		return
		
	Game.is_master = false
	Game.ui.ide.visible = true
	Game.ui.main_menu.visible = false
	reset()
	
	set_profile()


func _on_server_disconected():
	Game.ui.ide.visible = false
	Game.ui.main_menu.visible = true


func _on_tab_close_pressed(tab_index: int):
	var tab_scene: TabScene = Game.ui.scene_tabs.get_tab_control(tab_index)
	var map := tab_scene.map
	save_map(map)
	Game.maps.erase(map.slug)
	tab_scene.map.selected_level.get_node("Ceilling").free()
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
	Utils.reset_button_group(Game.ui.main_menu.campaign_buttons_group)
	Utils.reset_button_group(Game.ui.main_menu.server_buttons_group)
	
	Game.ui.tab_elements.reset()
	Game.ui.tab_builder.reset()
	Game.ui.tab_resources.reset()
	Game.ui.tab_properties.reset()
	for tab_scene in Game.ui.scene_tabs.get_children():
		tab_scene.queue_free()
	
	await get_tree().process_frame


func set_profile():
	if Game.is_master:
		Game.ui.nav_bar.visible = true
		Game.ui.left.visible = true
		Game.ui.middle_down.visible = true
		Game.ui.right_up.visible = true
		Game.ui.scene_tabs.tabs_visible = true
		Game.ui.right_down.tabs_visible = true
	else:
		Game.ui.nav_bar.visible = false
		Game.ui.left.visible = false
		Game.ui.middle_down.visible = false
		Game.ui.right_up.visible = false
		Game.ui.scene_tabs.tabs_visible = false
		Game.ui.right_down.tabs_visible = false


func safe_quit():
	if multiplayer.is_server():
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
