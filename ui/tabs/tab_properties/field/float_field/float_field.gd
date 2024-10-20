class_name FloatField
extends PropertyField


var property_value : float :
	set(value): spin_box.set_value_no_signal(value)
	get: return spin_box.value


@onready var spin_box: SpinBox = %SpinBox


func init(property_container: PropertyContainer, _property_name, _property_value := property_value):
	property_container.property_fields.add_child(self)
	property_name = _property_name
	property_value = _property_value
	return self


func _ready() -> void:
	spin_box.value_changed.connect(_on_value_changed)
