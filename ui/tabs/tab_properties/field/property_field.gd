@tool
class_name PropertyField
extends PanelContainer


signal value_changed(property_name: String, new_value: Variant)

@export var property_params := {} :
	set(value):
		for param in value:
			set_param(param, value[param])

var property_name := "Unnamed Property" :
	set(value):
		property_name = value
		label.text = value.capitalize()
		tooltip_text = value

@onready var label: Label = %Label


func init(property_container: PropertyContainer, _property_name: String, proprerty: Element.Property):
	property_container.property_fields.add_child(self)
	property_name = _property_name
	property_params = proprerty.params
	set_value(proprerty.value)
	return self
	

# override
func set_param(_param_name: String, _param_value: Variant):
	pass
	
# override
func set_value(_value: Variant):
	pass

func change_value(new_value: Variant):
	value_changed.emit(property_name, new_value)
