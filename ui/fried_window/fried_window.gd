class_name FriedWindow
extends Control


signal close_window


@export var is_invisible_on_close := false


@onready var close_button: Button = %CloseButton


func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)


func _on_close_button_pressed() -> void:
	if is_invisible_on_close:
		visible = false
		reset()
	else:
		queue_free()
		
	close_window.emit()


# override
func reset():
	pass
