class_name TabProperties
extends Control


signal element_changed(element: Element, property: String, value: Variant)


const PROPERTY_CONTAINER := preload("res://ui/tabs/tab_properties/container/property_container.tscn")
const STRING_FIELD := preload("res://ui/tabs/tab_properties/field/string_field/string_field.tscn")
const COLOR_FIELD := preload("res://ui/tabs/tab_properties/field/color_field/color_field.tscn")
const BOOL_FIELD := preload("res://ui/tabs/tab_properties/field/bool_field/bool_field.tscn")
const FLOAT_FIELD := preload("res://ui/tabs/tab_properties/field/float_field/float_field.tscn")


var element_selected: Element : set = _set_element_selected
var root_container: PropertyContainer
var containers_tree := {}


@onready var property_containers: VBoxContainer = %PropertyContainers


func _set_element_selected(value: Element):
	Utils.safe_queue_free(root_container)
	containers_tree.clear()
	if not value:
		if is_instance_valid(element_selected):
			Debug.print_message(Debug.DEBUG, "Element \"%s\" unselected" % element_selected.name)
		return
		
	element_selected = value
	Debug.print_message(Debug.INFO, "Element \"%s\" selected" % element_selected.name) 
	
	root_container = PROPERTY_CONTAINER.instantiate().init(property_containers)
	root_container.container_name = element_selected.name
	root_container.collapsable = false
	
	var properties := element_selected.properties
	_make_containers_tree(properties)
	
	for property_name in properties:
		var property: Element.Property = properties[property_name]
		var property_container: PropertyContainer = containers_tree[property.container]
		var field: PropertyField
		match property.hint:
			Element.Property.Hints.STRING:
				field = STRING_FIELD.instantiate().init(property_container, property_name, property.value)
			Element.Property.Hints.COLOR:
				field = COLOR_FIELD.instantiate().init(property_container, property_name, property.value)
			Element.Property.Hints.BOOL:
				field = BOOL_FIELD.instantiate().init(property_container, property_name, property.value)
			Element.Property.Hints.FLOAT:
				field = FLOAT_FIELD.instantiate().init(property_container, property_name, property.value)
			_:
				Debug.print_message(Debug.ERROR, "Unkown type \"%s\" of property \"%s\"" % [typeof(property.value), property_name]) 
		field.value_changed.connect(_on_field_value_changed)
		

func _make_containers_tree(properties: Dictionary):
	containers_tree[""] = root_container
	for property_name in properties:
		var property: Element.Property = properties[property_name]
		var container_name := property.container
		if not containers_tree.has(container_name):
			containers_tree[container_name] = PROPERTY_CONTAINER.instantiate().init(root_container)
			containers_tree[container_name].container_name = container_name


func _on_field_value_changed(property_name: String, new_value: Variant):
	element_selected.set_property_value(property_name, new_value)
