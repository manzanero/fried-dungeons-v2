extends Node

const UI_SCENE := preload("res://ui/ui.tscn")
const TAB_MAP := preload("res://ui/tabs/tab_map/tab_map.tscn")


func _ready() -> void:
	Game.ui = UI_SCENE.instantiate()
	add_child(Game.ui)
	var tab_map := TAB_MAP.instantiate()
	Game.ui.map_tabs.add_child(tab_map)
	tab_map.map.camera.fps_enabled.connect(_on_camera_fps_enabled)


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
	
	# restart the frame input handled
	Game.handled_input = false
	
	
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
