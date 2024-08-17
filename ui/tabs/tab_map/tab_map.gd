class_name TabMap
extends Control


@onready var map: Map = %Map


func _ready() -> void:
	mouse_entered.connect(func(): 
		map.camera.is_operated = true
		Game.ui.is_mouse_over_map_tab = true
		
		# prevent move focus when controlling cam with arrows
		focus_mode = FOCUS_ALL
		grab_focus()
		focus_mode = FOCUS_NONE
	)
	mouse_exited.connect(func(): 
		map.camera.is_operated = false
		Game.ui.is_mouse_over_map_tab = false
	)
