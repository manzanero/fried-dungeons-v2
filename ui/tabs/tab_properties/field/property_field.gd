class_name PropertyField
extends PanelContainer


signal value_changed(property_name: String, new_value: Variant)


var property_name := "Unnamed Property" :
	set(value):
		property_name = value
		label.text = value.capitalize()
		tooltip_text = value


@onready var label: Label = %Label


# override
func _on_value_changed(new_value: Variant):
	value_changed.emit(property_name, new_value)
