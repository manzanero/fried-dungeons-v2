class_name IntegerField
extends PropertyField

static var SCENE := preload("res://ui/tabs/tab_properties/field/integer_field/integer_field.tscn")

var property_value : int :
	set(value): number_edit.set_value_no_signal(value * 100 if is_percentage else value)
	get: return int(number_edit.value / 100.0 if is_percentage else number_edit.value)


var is_percentage: bool

@onready var number_edit: NumberEdit = %NumberEdit


func set_param(_param_name: String, _param_value: Variant):
	match _param_name:
		"is_percentage": is_percentage = _param_value
		"prefix": number_edit.prefix = _param_value
		"suffix": number_edit.suffix = _param_value
		"has_slider": number_edit.has_slider = _param_value
		"has_arrows": number_edit.has_arrows = _param_value
		"min_value": number_edit.min_value = _param_value
		"max_value": number_edit.max_value = _param_value
		"step": number_edit.step = _param_value
		"allow_greater": number_edit.allow_greater = _param_value
		"allow_lesser": number_edit.allow_lesser = _param_value


func set_value(_value: Variant):
	property_value = _value 
	

func _ready() -> void:
	number_edit.value_changed.connect(_on_int_value_changed)
	

func _on_int_value_changed(_new_value: int):
	value_changed.emit(property_name, property_value)
