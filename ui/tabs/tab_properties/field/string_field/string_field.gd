class_name StringField
extends PropertyField


var property_value : String :
	set(value): line_edit.text = value
	get: return line_edit.text


@onready var line_edit: LineEdit = %LineEdit


func set_param(_param_name: String, _param_value: Variant):
	pass


func set_value(_value: Variant):
	property_value = _value


func _ready() -> void:
	line_edit.text_changed.connect(_on_text_value_changed)


func _on_text_value_changed(new_text: String):
	value_changed.emit(property_name, new_text)
