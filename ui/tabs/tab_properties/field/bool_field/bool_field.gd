class_name BoolField
extends PropertyField


var property_value := false


@onready var check_box: CheckBox = %CheckBox


func init(property_container: PropertyContainer, _property_name, _property_value := property_value):
	property_container.property_fields.add_child(self)
	property_name = _property_name
	check_box.button_pressed = _property_value
	return self


func _ready() -> void:
	check_box.pressed.connect(_on_bool_value_changed)
	

func _on_bool_value_changed():
	value_changed.emit(property_name, check_box.button_pressed)
