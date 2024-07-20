class_name PropertyContainer
extends Control


const ARROW_DOWN = preload("res://resources/icons/arrow_down.png")
const ARROW_RIGHT = preload("res://resources/icons/arrow_right.png")


var container_name := "properties_container" :
	set(value):
		container_name = value
		properties_button.text = value.capitalize()
		properties_button.tooltip_text = value
var collapsable := true :
	set(value):
		collapsable = value
		properties_button.visible = value
		properties_button.visible = value
		background.visible = value
var collapsed := false :
	set(value):
		collapsed = value
		properties_button.icon = ARROW_RIGHT if value else ARROW_DOWN
		property_fields.visible = not collapsed


@onready var properties_button: Button = %CollapseButton
@onready var property_fields: VBoxContainer = %PropertyFields
@onready var background: Panel = %Background


func init(parent: Control, _container_name := container_name, _collapsable := collapsable, _collapsed := collapsed):
	parent.add_child(self)
	container_name = _container_name
	collapsable = _collapsable
	collapsed = _collapsed
	return self


func _ready() -> void:
	properties_button.pressed.connect(_on_button_pressed)
	

func _on_button_pressed():
	collapsed = not collapsed
	properties_button.icon = ARROW_RIGHT if collapsed else ARROW_DOWN


func clear():
	for child in property_fields.get_children():
		child.queue_free()
