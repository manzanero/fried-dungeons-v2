class_name IntegerField
extends PropertyField


var property_value : int :
	set(value): spin_box.value = value
	get: return spin_box.value


@onready var spin_box: SpinBox = %SpinBox


func init(property_container: PropertyContainer, _property_name, _property_value := property_value):
	property_container.property_fields.add_child(self)
	property_name = _property_name
	property_value = _property_value
	return self


func _ready() -> void:
	spin_box.value_changed.connect(_on_number_value_changed)
	

func _on_number_value_changed(new_value: float):
	value_changed.emit(property_name, new_value)
