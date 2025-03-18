class_name TabScene
extends Control

signal loaded

const PLAY_SCENE_ICON := preload("res://resources/icons/play_scene_icon.png")
const SCENE_ICON := preload("res://resources/icons/scene_icon.png")

@onready var sub_viewport: SubViewport = %SubViewport
@onready var world_3d: World3D = sub_viewport.world_3d

@onready var crt: Panel = %CRT
@onready var map: Map = %Map

@onready var fade_transition: FadeTransition = %FadeTransition
@onready var cursor_control: Control = $CursorControl


var is_mouse_over := false
var scene_has_focus := false


func init(map_slug: String, map_data: Dictionary, send_players := false):
	var new_tab_index := Game.ui.scene_tabs.get_tab_count()
	Game.ui.scene_tabs.add_child(self)
	map.slug = map_slug
	if send_players:
		Game.ui.scene_tabs.get_tab_bar().set_tab_icon(new_tab_index, PLAY_SCENE_ICON)
	else:
		Game.ui.scene_tabs.get_tab_bar().set_tab_icon(new_tab_index, SCENE_ICON)
	Game.manager.refresh_tabs()
	
	map.loader.load_map(map_data)
	for level: Level in map.levels_parent.get_children():
		level.light_viewport.find_world_3d()
	
	map.camera.position_2d = map.selected_level.rect.get_center()
	map.camera.fps_enabled.connect(_on_camera_fps_enabled)
	
	name = map_data.label
	sub_viewport.positional_shadow_atlas_size = Game.video_preferences.get_positional_shadow_atlas_size()
	sub_viewport.scaling_3d_scale = Game.video_preferences.scene_resolution
	
	Game.ui.tab_properties.settings.reset()
	
	crt.visible = Game.video_preferences.crt_filter
	
	item_rect_changed.connect(func ():
		crt.material.set_shader_parameter("resolution", sub_viewport.size)
	)
	
	loaded.emit()
	return self


func remove():
	Game.maps.erase(map.slug)
	queue_free()


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	cursor_control.gui_input.connect(_on_gui_input)


func _on_camera_fps_enabled(_value: bool):
	#if Game.master_is_player:
		#map.is_master_view = false
		#map.current_ambient_light = map.ambient_light
		#map.current_ambient_color = map.ambient_color
			#
	#else:
		#map.is_master_view = true
		#if value:
			#map.current_ambient_light = map.ambient_light
			#map.current_ambient_color = map.ambient_color
		#else:
			#map.current_ambient_light = map.master_ambient_light
			#map.current_ambient_color = map.master_ambient_color
		#
	#map.is_darkvision_view = Game.modes.darkvision_enabled
	#
	## exit build mode
	#Utils.reset_button_group(Game.modes.modes_button_group, true)
	#Game.ui.selected_map.selected_level.change_state(Level.State.GO_IDLE)
	pass


func _on_mouse_entered(): 
	# prevent trigger keys while writting or using a control
	if Game.control_uses_keyboard or Input.is_action_pressed("left_click"):
		return
		
	scene_grab_focus()


func scene_grab_focus():
	is_mouse_over = true
	scene_has_focus = true
	cursor_control.visible = false
	map.camera.is_operated = true
	get_viewport().gui_release_focus()


func _on_mouse_exited():
	is_mouse_over = false
	cursor_control.visible = true
		
		
func _on_gui_input(_event: InputEvent):
	is_mouse_over = true
	
	
func _can_drop_data(_at_position: Vector2, drop_data: Variant) -> bool:
	if not drop_data is Dictionary:
		return false
	if drop_data.get("type") != "campaign_blueprint_items":
		return false
	if not drop_data.get("items"):
		return false
	return true


func _drop_data(_at_position: Vector2, drop_data: Variant) -> void:
	var blueprint_item: TreeItem = drop_data.items[0]
	var blueprint: CampaignBlueprint = blueprint_item.get_metadata(0)
	match blueprint.type:
		CampaignBlueprint.Type.FOLDER:
			Utils.temp_error_tooltip("Drop an Element", 2, true)
		_:
			Game.ui.tab_blueprints.tree.item_activated.emit()
	scene_grab_focus()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if is_mouse_over:
				scene_grab_focus()
				#scene_has_focus = true
				#map.camera.is_operated = true
				#get_viewport().gui_release_focus()
			else:
				scene_has_focus = false
				map.camera.is_operated = false
