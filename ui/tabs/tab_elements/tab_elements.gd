class_name TabElements
extends Control


signal element_selected(element: Element)
signal element_activated(element: Element)


const ENTITIES_ICON = preload("res://resources/icons/entities_icon.png")
const LIGHT_ICON = preload("res://resources/icons/light_icon.png")
const OBJECT_ICON = preload("res://resources/icons/object_icon.png")

@onready var tree: Tree = %Tree

var entities_item: TreeItem
var lights_item: TreeItem
var objects_item: TreeItem


var elements := {}


func _ready() -> void:
	var root = tree.create_item()
	
	entities_item = tree.create_item(root)
	entities_item.set_selectable(0, false)
	entities_item.set_icon(0, ENTITIES_ICON)
	entities_item.set_text(0, "Entities")
	
	lights_item = tree.create_item(root)
	lights_item.set_selectable(0, false)
	lights_item.set_icon(0, LIGHT_ICON)
	lights_item.set_text(0, "Lights")
	
	objects_item = tree.create_item(root)
	objects_item.set_selectable(0, false)
	objects_item.set_icon(0, OBJECT_ICON)
	objects_item.set_text(0, "Objects")
	
	tree.item_selected.connect(_on_item_selected)
	tree.item_activated.connect(_on_item_activated)


func add_element(element: Element):
	var element_item: TreeItem
	if element is Entity:
		element_item = entities_item.create_child()
	elif element is Light:
		element_item = lights_item.create_child()
		
	element_item.set_text(0, element.label)
	element_item.set_metadata(0, element)

	elements[element.id] = element_item


func changed_element(element: Element):
	var element_item: TreeItem = elements[element.id]
	element_item.set_text(0, element.label)


func remove_element(element: Element):
	var element_item: TreeItem = elements[element.id]
	element_item.get_parent().remove_child(element_item)
	

func _on_item_selected():
	var item_selected := tree.get_selected()
	element_selected.emit(item_selected)
	
	var element: Element = item_selected.get_metadata(0)
	if element.level.element_selected:
		element.level.element_selected.is_selected = false
	element.is_selected = true
	

func _on_item_activated():
	var item_selected := tree.get_selected()
	element_activated.emit(item_selected)
	
	var element: Element = item_selected.get_metadata(0)
	element.map.camera.target_position.position = element.position + Vector3.UP * 0.5
