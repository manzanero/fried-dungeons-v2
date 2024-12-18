class_name TabProperties
extends Control


const PROPERTY_CONTAINER := preload("res://ui/tabs/tab_properties/container/property_container.tscn")
const STRING_FIELD := preload("res://ui/tabs/tab_properties/field/string_field/string_field.tscn")
const COLOR_FIELD := preload("res://ui/tabs/tab_properties/field/color_field/color_field.tscn")
const BOOL_FIELD := preload("res://ui/tabs/tab_properties/field/bool_field/bool_field.tscn")
const FLOAT_FIELD := preload("res://ui/tabs/tab_properties/field/float_field/float_field.tscn")
const INTEGER_FIELD := preload("res://ui/tabs/tab_properties/field/integer_field/integer_field.tscn")
const VECTOR_2_FIELD := preload("res://ui/tabs/tab_properties/field/vector_2_field/vector_2_field.tscn")
const TEXTURE_FIELD := preload("res://ui/tabs/tab_properties/field/texture_field/texture_field.tscn")
const CHOICE_FIELD := preload("res://ui/tabs/tab_properties/field/choice_field/choice_field.tscn")


var element_selected: Element : set = _set_element_selected
var root_container: PropertyContainer
var containers_tree := {}


@onready var property_containers: VBoxContainer = %PropertyContainers


func _set_element_selected(element: Element):
	Utils.safe_queue_free(root_container)
	containers_tree.clear()
	if not element:
		if is_instance_valid(element_selected):
			Debug.print_debug_message("Element \"%s\" unselected" % element_selected.name)
		return
		
	element_selected = element
	Debug.print_info_message("Element \"%s\" selected" % element_selected.name) 
	
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
				field = STRING_FIELD.instantiate().init(property_container, property_name, property)
			Element.Property.Hints.COLOR:
				field = COLOR_FIELD.instantiate().init(property_container, property_name, property)
			Element.Property.Hints.CHOICE:
				field = CHOICE_FIELD.instantiate().init(property_container, property_name, property)
			Element.Property.Hints.BOOL:
				field = BOOL_FIELD.instantiate().init(property_container, property_name, property)
			Element.Property.Hints.FLOAT:
				field = FLOAT_FIELD.instantiate().init(property_container, property_name, property)
			Element.Property.Hints.INTEGER:
				field = INTEGER_FIELD.instantiate().init(property_container, property_name, property)
			Element.Property.Hints.VECTOR_2:
				field = VECTOR_2_FIELD.instantiate().init(property_container, property_name, property)
			Element.Property.Hints.TEXTURE:
				field = TEXTURE_FIELD.instantiate().init(property_container, property_name, property)
			_:
				Debug.print_error_message("Unkown type \"%s\" of property \"%s\"" % [typeof(property.value), property_name]) 
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
	var level: Level = element_selected.level
	var map: Map = level.map
	var id := element_selected.id
	Game.server.rpcs.change_element_property.rpc(map.slug, level.index, id, property_name, new_value)


func reset():
	_set_element_selected(null)
