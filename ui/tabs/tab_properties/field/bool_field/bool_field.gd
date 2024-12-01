class_name BoolField
extends PropertyField


var property_value : bool :
	set(value): check_box.button_pressed = value
	get: return check_box.button_pressed


@onready var check_box: CheckBox = %CheckBox


func set_param(_param_name: String, _param_value: Variant):
	pass


func set_value(_value: Variant):
	property_value = _value


func _ready() -> void:
	check_box.pressed.connect(_on_bool_value_changed)
	

func _on_bool_value_changed():
	value_changed.emit(property_name, property_value)
