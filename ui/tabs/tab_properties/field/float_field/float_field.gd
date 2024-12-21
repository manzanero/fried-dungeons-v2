class_name FloatField
extends PropertyField


static var SCENE := preload("res://ui/tabs/tab_properties/field/float_field/float_field.tscn")


var property_value: float :
	set(value): number_edit.set_value_no_signal(value)
	get: return number_edit.value


@onready var number_edit: NumberEdit = %NumberEdit


func set_param(param_name: String, param_value: Variant):
	match param_name:
		"prefix": number_edit.prefix = param_value
		"suffix": number_edit.suffix = param_value
		"has_slider": number_edit.has_slider = param_value
		"has_arrows": number_edit.has_arrows = param_value
		"rounded": number_edit.rounded = param_value
		"min_value": number_edit.min_value = param_value
		"max_value": number_edit.max_value = param_value
		"step": number_edit.step = param_value
		"allow_greater": number_edit.allow_greater = param_value
		"allow_lesser": number_edit.allow_lesser = param_value


func set_value(_value: Variant):
	property_value = _value


func _ready() -> void:
	number_edit.value_changed.connect(change_value)
