class_name Vector2Field
extends PropertyField


var property_value: Vector2 :
	set(value): x_number_edit.set_value_no_signal(value.x); y_number_edit.set_value_no_signal(value.y)
	get: return Vector2(x_number_edit.value, y_number_edit.value)


@onready var x_number_edit: NumberEdit = %XNumberEdit
@onready var y_number_edit: NumberEdit = %YNumberEdit


func set_param(_param_name: String, _param_value: Variant):
	match _param_name:
		"x_prefix": x_number_edit.prefix = _param_value
		"y_prefix": y_number_edit.prefix = _param_value
		"x_suffix": x_number_edit.suffix = _param_value
		"y_suffix": y_number_edit.suffix = _param_value
		"rounded": y_number_edit.rounded = _param_value
		"x_min_value": x_number_edit.min_value = _param_value
		"y_min_value": y_number_edit.min_value = _param_value
		"x_max_value": x_number_edit.max_value = _param_value
		"y_max_value": y_number_edit.max_value = _param_value
		"step": x_number_edit.step_value = _param_value; y_number_edit.step_value = _param_value
		"allow_greater": x_number_edit.allow_greater = _param_value; y_number_edit.allow_greater = _param_value
		"allow_lesser": x_number_edit.allow_lesser = _param_value; y_number_edit.allow_lesser = _param_value


func set_value(_value: Variant):
	property_value = _value


func _ready() -> void:
	x_number_edit.value_changed.connect(_on_vector_2_value_changed.unbind(1))
	y_number_edit.value_changed.connect(_on_vector_2_value_changed.unbind(1))
	

func _on_vector_2_value_changed():
	value_changed.emit(property_name, property_value)
