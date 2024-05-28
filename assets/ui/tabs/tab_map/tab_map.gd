class_name TabMap
extends Control


@onready var map: Map = %Map


var is_mouse_over := true


func _ready() -> void:
	mouse_entered.connect(func(): 
		is_mouse_over = true
	)
	mouse_exited.connect(func(): 
		is_mouse_over = false
	)
