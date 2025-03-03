class_name TabElements
extends Control


signal element_selected(element: Element)
signal element_activated(element: Element)


const ENTITY_ICON = preload("res://resources/icons/entities_white_icon.png")
const LIGHT_ICON = preload("res://resources/icons/sun_icon.png")
const PROP_ICON = preload("res://resources/icons/prop_icon.png")
const PIN_ICON = preload("res://resources/icons/pin_icon.png")
const GODOT_ICON = preload("res://resources/icons/godot_icon.png")

@onready var new_button: MenuButton = %NewButton
@onready var label_line_edit: LineEdit = %LabelLineEdit
@onready var pinned_button: Button = %PinnedButton
@onready var tree: DraggableTree = %DraggableTree
@onready var duplicate_button: Button = %DuplicateButton
@onready var remove_button: Button = %RemoveButton


var root: TreeItem
var element_items := {}


func _ready() -> void:
	reset()
	var new_popup := new_button.get_popup()
	new_popup.get_window().transparent = true
	new_popup.id_pressed.connect(_on_new_popup_id_pressed)
	label_line_edit.text_changed.connect(_on_label_filter_changed.unbind(1))
	pinned_button.pressed.connect(tree.scroll_to_item.bind(root).call)
	tree.item_activated.connect(_on_item_activated)
	tree.button_clicked.connect(_on_button_clicked)
	tree.items_dropped.connect(_on_items_dropped)
	tree.item_mouse_selected.connect(_on_item_mouse_selected)
	tree.empty_clicked.connect(tree.deselect_all.unbind(2))
	duplicate_button.pressed.connect(_on_duplicate_button_pressed)
	remove_button.pressed.connect(_on_remove_button_pressed)
	

func _on_new_popup_id_pressed(id: int) -> void:
	match id:
		0: Game.modes.change_mode(ModeController.Mode.LIGHT_OMNILIGHT)
		1: Game.modes.change_mode(ModeController.Mode.ENTITY_3D_SHAPE)
		2: Game.modes.change_mode(ModeController.Mode.PROP_3D_SHAPE)
	

func _on_label_filter_changed():
	var visibles: Array[TreeItem] = [root]
	var filter := label_line_edit.text.to_lower()
	for item: TreeItem in element_items.values():
		var label := item.get_text(0)
		if filter and filter not in label.to_lower():
			item.visible = false
		else:
			item.visible = true
			visibles.append(item)
			var parent := item.get_parent()
			while parent not in visibles:
				parent.visible = true
				parent = parent.get_parent()
	root.visible = true
	
	
func _on_duplicate_button_pressed():
	if not tree.get_selected() or tree.get_selected() == root:
		Utils.temp_error_tooltip("Select an Element")
		return
	var element: Element = tree.get_selected().get_metadata(0)
		
	match element.type:
		Element.Type.ENTITY: Game.modes.change_mode(ModeController.Mode.ENTITY_3D_SHAPE)
		Element.Type.LIGHT: Game.modes.change_mode(ModeController.Mode.LIGHT_OMNILIGHT)
		Element.Type.PROP: Game.modes.change_mode(ModeController.Mode.PROP_3D_SHAPE)
		
	element.level.state_machine.get_state_node(Level.State.GO_ELEMENT_INSTANCING).preview_label = element.label
	element.level.state_machine.get_state_node(Level.State.GO_ELEMENT_INSTANCING).preview_properties = element.get_property_values()
	
	
func _on_remove_button_pressed():
	var item_selected := tree.get_selected()
	if not item_selected:
		Utils.temp_error_tooltip("Select an Element to remove")
		return
	
	var element: Element = item_selected.get_metadata(0)
	
	if Input.is_key_pressed(KEY_SHIFT):
		element.remove()
		Game.server.rpcs.remove_element.rpc(element.map.slug, element.level.index, element.id)
	else:
		tree.release_focus()
		Game.ui.delete_window.visible = true
		Game.ui.delete_window.item_type = "Element"
		Game.ui.delete_window.item_selected = element.label
		
		var response = await Game.ui.delete_window.response
		tree.grab_focus()
		if response:
			element.remove()
			Game.server.rpcs.remove_element.rpc(element.map.slug, element.level.index, element.id)


func add_element(element: Element):
	var element_item := root.create_child()
	element_item.set_text(0, element.label)
	element_item.set_tooltip_text(0, element.id)
	element_item.add_button(0, PIN_ICON)
	element_item.set_button_color(0, 0, Game.TREE_BUTTON_OFF_COLOR)
	if element.is_favourite:
		element_item.set_button_color(0, 0, Color.WHITE)
	element_item.set_metadata(0, element)
	match element.type:
		"light": element_item.set_icon(0, LIGHT_ICON)
		"entity": element_item.set_icon(0, ENTITY_ICON)
		"prop": element_item.set_icon(0, PROP_ICON)
		_: element_item.set_icon(0, GODOT_ICON)
		
	element_item.set_icon_modulate(0, Utils.color_for_dark_bg(element.color))

	element_items[element.id] = element_item
	

func select_element(element: Element):
	activate_element(null)
	
	if not element:
		tree.deselect_all()
		return
	
	var element_item: TreeItem = element_items.get(element.id)
	if not element_item:
		return
	
	element_item.select(0)
	tree.scroll_to_item(element_item) 
	

func activate_element(element: Element):
	for item: TreeItem in element_items.values():
		item.clear_custom_color(0)
	
	if not element:
		return
	
	var element_item: TreeItem = element_items.get(element.id)
	if not element_item:
		return

	element_item.set_custom_color(0, Color.GREEN)
	tree.scroll_to_item(element_item) 
	

func changed_element(element: Element):
	var element_item: TreeItem = element_items.get(element.id)
	if not element_item:
		return
	
	var old_label := element_item.get_text(0)
	element_item.set_text(0, element.label)
	element_item.set_icon_modulate(0, Utils.color_for_dark_bg(element.color))
	
	if old_label != element.label:
		sort_children(element_item.get_parent())
	
	element_item.select(0)


func remove_element(element: Element):
	var element_item: TreeItem = element_items.get(element.id)
	if not element_item:
		Debug.print_warning_message("Can't delete element item of \"%s\"" % element.id)
		return
		
	element_items.erase(element.id)
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
	
	var is_activated := item_selected.get_custom_color(0) == Color.GREEN
	if is_activated:
		activate_element(null)
	else:
		activate_element(element)
	
	element.map.camera.position_3d = element.position


func _on_button_clicked(item: TreeItem, _column: int, _id: int, _mouse_button_index: int):
	var element: Element = item.get_metadata(0)
	element.is_favourite = not element.is_favourite
	item.set_button_color(0, 0, Game.TREE_BUTTON_ON_COLOR if element.is_favourite else Game.TREE_BUTTON_OFF_COLOR)
	sort_children(root)
	#tree.scroll_to_item(item)
	#item.select(0)
	

func _on_items_dropped(_drop_data: Dictionary, _item_at_position: TreeItem, _drop_section: int):
	return
	

func reset():
	element_items.clear()
	tree.clear()
	root = tree.create_item()
	
	if not Game.ui.selected_map:
		return
	
	for level: Level in Game.ui.selected_map.levels.values():
		for element: Element in level.elements.values():
			if not is_instance_valid(element):
				Debug.print_warning_message("Element \"%s\" was freed" % element.id)
				continue
			
			#if element.is_preview
				
			add_element(element)
	
	sort_children(root)


func sort_children(item: TreeItem):
	var favourite_elements: Array[TreeItem] = []
	for child: TreeItem in item.get_children():
		sort_children(child)
		var element: Element = child.get_metadata(0)
		if element.is_favourite:
			favourite_elements.append(child)
			
	var sorted_children := item.get_children()
	sorted_children.sort_custom(func(a: TreeItem, b: TreeItem) -> int:
		if a in favourite_elements and b not in favourite_elements:
			return true
		if a not in favourite_elements and b in favourite_elements:
			return false
		var label_a := a.get_text(0)
		var label_b := b.get_text(0)
		if label_a == label_b:
			return a.get_index() < b.get_index()
		return label_a.naturalnocasecmp_to(label_b) == -1
	)
	for child in item.get_children():
		item.remove_child(child)
	for child in sorted_children:
		item.add_child(child)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			if tree.has_focus():
				if event.keycode == KEY_DELETE:
					tree.release_focus()
					_on_remove_button_pressed()
					get_viewport().set_input_as_handled()
