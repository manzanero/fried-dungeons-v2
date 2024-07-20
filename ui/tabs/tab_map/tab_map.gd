class_name TabMap
extends Control


@onready var map: Map = %Map


func _ready() -> void:
	mouse_entered.connect(func(): 
		map.camera.is_operated = true
		Game.ui.is_mouse_over_map_tab = true
	)
	mouse_exited.connect(func(): 
		map.camera.is_operated = false
		Game.ui.is_mouse_over_map_tab = false
	)
