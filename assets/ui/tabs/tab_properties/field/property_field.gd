class_name PropertyField
extends PanelContainer


signal value_changed(property_name: String, new_value: Variant)


var property_name: String :
	set(value):
		property_name = value
		label.text = value.capitalize()
		tooltip_text = value


@onready var label: Label = %Label
