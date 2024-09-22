class_name TabElements
extends Control


signal element_selected(element: Element)
signal element_activated(element: Element)


const ENTITIES_ICON = preload("res://resources/icons/entities_icon.png")
const LIGHT_ICON = preload("res://resources/icons/light_icon.png")
const OBJECT_ICON = preload("res://resources/icons/object_icon.png")

@onready var tree: DraggableTree = %DraggableTree

var entities_item: TreeItem
var lights_item: TreeItem
var objects_item: TreeItem


var root: TreeItem
var elements := {}


func _ready() -> void:
	reset()
	tree.item_selected.connect(_on_item_selected)
	tree.item_activated.connect(_on_item_activated)
	tree.items_moved.connect(_on_items_moved)


func add_element(element: Element):
	var element_item := root.create_child()
	
	if element is Entity:
		element_item.set_icon(0, ENTITIES_ICON)
	elif element is Light:
		element_item.set_icon(0, LIGHT_ICON)
		
	element_item.set_text(0, "%s" % element.label)
	element_item.set_tooltip_text(0, element.id)
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
	if is_instance_valid(element.level.element_selected):
		element.level.element_selected.is_selected = false
	element.is_selected = true


func _on_item_activated():
	var item_selected := tree.get_selected()
	element_activated.emit(item_selected)
	
	var element: Element = item_selected.get_metadata(0)
	element.map.camera.target_position.position = element.position + Vector3.UP * 0.5


func _on_items_moved(items: Array[TreeItem], index: int):
	var elements_moved: Array[Element] = []
	var ids: Array[String] = []
	for item: TreeItem in items:
		var element: Element = item.get_metadata(0)
		elements_moved.append(element)
		ids.append(element.id)
		
	Debug.print_info_message("Elements %s moved to index %s" % [ids, index])
	
	# TODO multiselection
	
	var element_moved := elements_moved[0]
	Game.ui.selected_map.selected_level.elements_parent.move_child(element_moved, index)
	Game.ui.selected_map.selected_level.elements.clear()
	for element: Element in Game.ui.selected_map.selected_level.elements_parent.get_children():
		Game.ui.selected_map.selected_level.elements[element.id] = element


func reset():
	elements.clear()
	tree.clear()
	root = tree.create_item()
	
	if Game.ui.selected_map and Game.ui.selected_map.selected_level:
		var elements_data := Game.ui.selected_map.selected_level.elements
		for element: Element in elements_data.values():
			add_element(element)
