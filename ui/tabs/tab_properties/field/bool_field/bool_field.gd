@tool
class_name BoolField
extends PropertyField


static var SCENE := preload("res://ui/tabs/tab_properties/field/bool_field/bool_field.tscn")


var property_value : bool :
	set(value): 
		check_box.button_pressed = value
		check_box.text = "Yes" if value else "No"
	get: return check_box.button_pressed


@onready var check_box: CheckBox = %CheckBox


func set_param(_param_name: String, _param_value: Variant):
	pass


func set_value(_value: Variant):
	property_value = _value


func _ready() -> void:
	check_box.pressed.connect(_on_bool_value_changed)
	

func _on_bool_value_changed():
	check_box.text = "Yes" if property_value else "No"
	value_changed.emit(property_name, property_value)
