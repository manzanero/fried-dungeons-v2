class_name ColorField
extends PropertyField


const SCENE := preload("res://ui/tabs/tab_properties/field/color_field/color_field.tscn")
	
	
@export var color_edit: ColorEdit

var property_value := Color.WHITE :
	set(value): color_edit.color = value
	get: return color_edit.color


func set_param(_param_name: String, _param_value: Variant):
	pass


func set_value(_value: Variant):
	property_value = _value


func _ready() -> void:
	color_edit.color_changed.connect(_on_color_value_changed)
	
	
func _on_color_value_changed(new_value: Color):
	value_changed.emit(property_name, new_value)
