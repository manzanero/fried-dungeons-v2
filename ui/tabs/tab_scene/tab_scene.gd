class_name TabScene
extends Control

@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var world_3d: World3D = sub_viewport.world_3d

@onready var map: Map = %Map

@onready var cursor_control: Control = $CursorControl

var is_mouse_over := false


func init(map_slug: String, map_data: Dictionary):
	Game.ui.scene_tabs.add_child(self)
	Game.maps[map_slug] = map
	
	#map.init_test_data()
	map.loader.load_map(map_data)
	map.slug = map_slug
	for level: Level in map.levels_parent.get_children():
		level.light_viewport.find_world_3d()
	
	map.camera.target_position.position = Utils.v2i_to_v3(map.selected_level.rect.get_center()) + Vector3.UP * 0.5
	map.camera.fps_enabled.connect(_on_camera_fps_enabled)
	
	name = map_data.label
	return self


func _ready() -> void:
	cursor_control.visible = true
	
	mouse_entered.connect(func(): 
		is_mouse_over = true
		
		# prevent have previous shape
		cursor_control.visible = false
		
		# prevent move focus when controlling cam with arrows
		focus_mode = FOCUS_ALL
		grab_focus()
		focus_mode = FOCUS_NONE
	)
	mouse_exited.connect(func():
		is_mouse_over = false
		
		cursor_control.visible = true
	)
	
	cursor_control.gui_input.connect(func (_event: InputEvent):
		cursor_control.visible = false
	)


func _on_camera_fps_enabled(value: bool):
	var light := Game.ui.tab_settings.ambient_light_spin.value / 100.0
	var color := Game.ui.tab_settings.ambient_color_button.color
	if value:
		Game.ui.tab_settings.ambient_changed.emit(true, light, color)
	else:
		if Game.is_master:
			Game.ui.tab_settings.master_view_check.pressed.emit()
		else:
			Game.ui.tab_settings.ambient_changed.emit(false, light, color)
	
	# exit build mode
	var builder_button_pressed = Game.ui.tab_builder.wall_button.button_group.get_pressed_button()
	if builder_button_pressed:
		var state_machine := Game.ui.selected_map.selected_level.state_machine
		state_machine.change_state("Idle")
		builder_button_pressed.button_pressed = false
	
	if Game.is_master:
		get_tree().set_group("lights", "hidden", value)
	
	get_tree().set_group("base", "visible", not value)