class_name TabMap
extends Control


@onready var map: Map = %Map

@onready var cursor_control: Control = $CursorControl


func _ready() -> void:
	cursor_control.visible = true
	
	mouse_entered.connect(func(): 
		Game.ui.is_mouse_over_map_tab = true
		
		# prevent have previous shape
		cursor_control.visible = false
		
		# prevent move focus when controlling cam with arrows
		focus_mode = FOCUS_ALL
		grab_focus()
		focus_mode = FOCUS_NONE
	)
	mouse_exited.connect(func():
		Game.ui.is_mouse_over_map_tab = false
		
		cursor_control.visible = true
	)
	
	cursor_control.gui_input.connect(func (event: InputEvent):
		cursor_control.visible = false
	)
