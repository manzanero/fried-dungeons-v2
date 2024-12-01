class_name ColorField
extends PropertyField


var property_value := Color.WHITE :
	set(value): color_picker_button.color = value
	get: return color_picker_button.color


@onready var color_picker_button: ColorPickerButton = %ColorPickerButton


func set_param(_param_name: String, _param_value: Variant):
	pass


func set_value(_value: Variant):
	property_value = _value


func _ready() -> void:
	color_picker_button.color_changed.connect(_on_color_value_changed)
	

func _on_color_value_changed(new_value: Color):
	value_changed.emit(property_name, new_value)
