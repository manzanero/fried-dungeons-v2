class_name FloatField
extends PropertyField


var property_value := 0.0


@onready var spin_box: SpinBox = %SpinBox


func init(property_container: PropertyContainer, _property_name, _property_value := property_value):
	property_container.property_fields.add_child(self)
	property_name = _property_name
	spin_box.value = _property_value
	return self


func _ready() -> void:
	spin_box.value_changed.connect(_on_value_changed)
	

func _on_value_changed(new_value: float):
	value_changed.emit(property_name, new_value)
