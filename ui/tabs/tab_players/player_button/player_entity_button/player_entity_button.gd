extends Button


signal left_button_pressed()
signal right_button_pressed()


func _ready() -> void:
	gui_input.connect(_on_button_gui_input)


func _on_button_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				left_button_pressed.emit()
			MOUSE_BUTTON_RIGHT:
				right_button_pressed.emit()
