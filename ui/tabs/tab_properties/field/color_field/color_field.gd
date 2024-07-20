class_name ColorField
extends PropertyField


var property_value := Color.WHITE


@onready var color_picker_button: ColorPickerButton = %ColorPickerButton


func init(property_container: PropertyContainer, _property_name, _property_value := property_value):
	property_container.property_fields.add_child(self)
	property_name = _property_name
	color_picker_button.color = _property_value
	return self


func _ready() -> void:
	color_picker_button.color_changed.connect(_on_value_changed)
	

func _on_value_changed(new_value: Color):
	value_changed.emit(property_name, new_value)
