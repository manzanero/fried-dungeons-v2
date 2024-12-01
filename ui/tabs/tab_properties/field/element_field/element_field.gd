class_name ElementField
extends PropertyField


var property_value : String :
	set(value): line_edit.value = value
	get: return line_edit.value


@onready var line_edit: LineEdit = %LineEdit


func set_param(_param_name: String, _param_value: Variant):
	pass


func set_value(_value: Variant):
	property_value = _value


func _ready() -> void:
	line_edit.text_changed.connect(_on_text_value_changed)
	

func _on_text_value_changed(new_text: String):
	if Game.ui.selected_map.selected_level.elements.has(new_text):
		value_changed.emit(property_name, new_text)
	else:
		value_changed.emit(property_name, "")
