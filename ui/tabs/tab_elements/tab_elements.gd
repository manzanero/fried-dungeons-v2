class_name TabElements
extends Control


signal element_selected(element: Element)
signal element_activated(element: Element)


const ENTITIES_ICON = preload("res://resources/icons/entities_icon.png")
const LIGHT_ICON = preload("res://resources/icons/light_icon.png")
const PROP_ICON = preload("res://resources/icons/shape_icon.png")

@onready var tree: DraggableTree = %DraggableTree


var root: TreeItem
var elements := {}


func _ready() -> void:
	reset()
	tree.item_activated.connect(_on_item_activated)
	tree.items_dropped.connect(_on_items_dropped)
	tree.item_mouse_selected.connect(_on_item_mouse_selected)


func add_element(element: Element):
	var element_item := root.create_child()
	
	if element is Entity:
		element_item.set_icon(0, ENTITIES_ICON)
	elif element is Light:
		element_item.set_icon(0, LIGHT_ICON)
	elif element is Prop:
		element_item.set_icon(0, PROP_ICON)
		
	element_item.set_text(0, "%s" % element.label)
	element_item.set_tooltip_text(0, element.id)
	element_item.set_metadata(0, element)

	elements[element.id] = element_item


func changed_element(element: Element):
	var element_item: TreeItem = elements.get(element.id)
	if element_item:
		element_item.set_text(0, element.label)


func remove_element(element: Element):
	Debug.print_info_message("Deleting element item of \"%s\"" % element.id)
	
	var element_item: TreeItem = elements.get(element.id)
	if not element_item:
		Debug.print_warning_message("Can't delete element item of \"%s\"" % element.id)
		return
		
	if element_item.get_parent():
		element_item.get_parent().remove_child(element_item)
	else:
		Debug.print_warning_message("Element item of \"%s\" is orphan" % element.id)
		element_item.free()
		

func _on_item_mouse_selected(_mouse_position: Vector2, mouse_button_index: int):
	var item_selected := tree.get_selected()
	element_selected.emit(item_selected)
	var element: Element = item_selected.get_metadata(0)
	
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		Game.ui.tab_builder.reset()
		if is_instance_valid(element.level.element_selected):
			element.level.element_selected.is_selected = false
		element.is_selected = true
	
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		DisplayServer.clipboard_set(element.id)
		Utils.temp_info_tooltip("Copied!", 1)


func _on_item_activated():
	var item_selected := tree.get_selected()
	if not is_instance_valid(item_selected):
		return
		
	element_activated.emit(item_selected)

	var element: Element = item_selected.get_metadata(0)
	element.map.camera.target_position.position = element.position + Vector3.UP * 0.5


func _on_items_dropped(_drop_data: Dictionary, _item_at_position: TreeItem, _drop_section: int):
	return
	

func reset():
	elements.clear()
	tree.clear()
	root = tree.create_item()
	
	if Game.ui.selected_map and Game.ui.selected_map.selected_level:
		var elements_data := Game.ui.selected_map.selected_level.elements
		for element: Element in elements_data.values():
			if not element or not is_instance_valid(element):
				Debug.print_warning_message("Element \"%s\" was freed" % element.id)
				continue
			add_element(element)
