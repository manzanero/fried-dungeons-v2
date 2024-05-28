class_name StringField
extends PropertyField


var property_value := ""


@onready var line_edit: LineEdit = %LineEdit


func init(property_container: PropertyContainer, _property_name, _property_value := property_value):
	property_container.property_fields.add_child(self)
	property_name = _property_name
	line_edit.text = _property_value
	return self


func _ready() -> void:
	line_edit.text_changed.connect(_on_value_changed)
	

func _on_value_changed(new_text: String):
	value_changed.emit(property_name, new_text)
