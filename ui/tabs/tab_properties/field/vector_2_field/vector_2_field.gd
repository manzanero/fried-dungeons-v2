class_name Vector2Field
extends PropertyField


var property_value: Vector2 :
	set(value): x_spin_box.set_value_no_signal(value.x); y_spin_box.set_value_no_signal(value.y)
	get: return Vector2(x_spin_box.value, y_spin_box.value)


@onready var x_spin_box: SpinBox = %XSpinBox
@onready var y_spin_box: SpinBox = %YSpinBox


func init(property_container: PropertyContainer, _property_name, _property_value := property_value):
	property_container.property_fields.add_child(self)
	property_name = _property_name
	x_spin_box.value = _property_value.x
	y_spin_box.value = _property_value.y
	return self


func _ready() -> void:
	x_spin_box.value_changed.connect(_on_vector_2_value_changed.unbind(1))
	y_spin_box.value_changed.connect(_on_vector_2_value_changed.unbind(1))
	

func _on_vector_2_value_changed():
	value_changed.emit(property_name, property_value)
