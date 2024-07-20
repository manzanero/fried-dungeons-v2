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
		
	get_tree().set_group("lights", "hidden", value)
	

func _process(_delta: float) -> void:
	
	# restart the frame input handled
	Game.handled_input = false
