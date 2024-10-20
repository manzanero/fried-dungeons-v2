class_name StringField
extends PropertyField


var property_value : String :
	set(value): line_edit.value = value
	get: return line_edit.value


@onready var line_edit: LineEdit = %LineEdit


func init(property_container: PropertyContainer, _property_name, _property_value := property_value):
	property_container.property_fields.add_child(self)
	property_name = _property_name
	line_edit.text = _property_value
	return self


func _ready() -> void:
	line_edit.text_changed.connect(_on_text_value_changed)
	

func _on_text_value_changed(new_text: String):
	value_changed.emit(property_name, new_text)
