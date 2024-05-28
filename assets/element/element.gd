class_name Element
extends CharacterBody3D


signal property_changed(property_name: StringName, old_value: Variant, new_value: Variant)


@export var properties := {}
@onready var elements: Node3D = $Elements


func init_property(container: String, property_name: StringName, property_hint: StringName, default_value: Variant = null) -> void:
	properties[property_name] = Property.new(container, property_hint, default_value)


func set_property_value(property_name: StringName, new_value: Variant) -> void:
	var old_value = properties.get(property_name).value if properties.has(property_name) else null
	if old_value == new_value:
		return
		
	properties[property_name].value = new_value
	property_changed.emit(property_name, old_value, new_value)
	
	
func get_property(property_name: StringName, default: Variant) -> Property:
	return properties.get(property_name, default)
	

func merge_properties(properties_dict: Dictionary):
	for property_name in properties_dict:
		set_property_value(property_name, properties_dict[property_name])
		
		
func update_properties():
	for property_name in properties:
		property_changed.emit(property_name, null, properties[property_name].value)


class Property:
	var hint: StringName
	var value: Variant
	var container: String
	
	func _init(_container: String, _hint: StringName, _value: Variant):
		hint = _hint
		value = _value
		container = _container

	class Hints:
		const BOOL = &"bool_hint"
		const COLOR = &"color_hint"
		const FLOAT = &"float_hint"
		const INTEGER = &"integer_hint"
		const STRING = &"string_hint"
		const TEXT_AREA = &"text_area_hint"
