class_name DraggableTree
extends Tree


signal items_dropped(type: String, items: Array, item_at_position: TreeItem, drop_section: int)

@export var allow_drag := false
@export var drag_type := "any"

@export var allow_drop_blank := false
@export var allow_drop_on_item := false
@export var allow_drop_inbetween := false

@export var drop_types_allowed: PackedStringArray = ["any"]


var allow_drop : bool :
	get: return allow_drop_blank or allow_drop_on_item or allow_drop_inbetween


func _get_drag_data(_at_position: Vector2):
	if not allow_drag:
		return
		
	var drag_data := {
		"type": drag_type,
		"items": [],
	}
	
	var next: TreeItem = get_next_selected(null)
	var drag_preview := VBoxContainer.new()
	while next:
		drag_data.items.append(next)
		
		var label := Label.new()
		label.text = next.get_text(0)
		drag_preview.add_child(label)
		
		next = get_next_selected(next)
		
	set_drag_preview(drag_preview)
	return drag_data


func _can_drop_data(at_position: Vector2, drop_data: Variant) -> bool:
	if not allow_drop:
		return false
	if not drop_data is Dictionary:
		return false
	if drop_data.get("type") not in drop_types_allowed and "any" not in drop_types_allowed:
		return false
	var items: Array = drop_data.get("items")
	if not items:
		return false
		
	var root: TreeItem = items[0].get_tree().get_root()
	if root in items:
		drop_mode_flags = Tree.DROP_MODE_DISABLED
		return false
	
	if allow_drop_on_item and allow_drop_inbetween:
		drop_mode_flags = Tree.DROP_MODE_ON_ITEM | Tree.DROP_MODE_INBETWEEN
	elif allow_drop_on_item:
		drop_mode_flags = Tree.DROP_MODE_ON_ITEM
	elif allow_drop_inbetween:
		drop_mode_flags = Tree.DROP_MODE_INBETWEEN
		
	var drop_section := get_drop_section_at_position(at_position)
	if drop_section == -100:
		return allow_drop_blank
		
	var item_at_position := get_item_at_position(at_position)
	for item in items:
		if item_at_position == item:
			drop_mode_flags = Tree.DROP_MODE_DISABLED
			return false
		if Utils.is_tree_descendant(item_at_position, item):
			drop_mode_flags = Tree.DROP_MODE_DISABLED
			return false
			
	if item_at_position == root:
		if not allow_drop_on_item:
			drop_mode_flags = Tree.DROP_MODE_DISABLED
			return false
			
		drop_mode_flags = Tree.DROP_MODE_ON_ITEM
		drop_section = get_drop_section_at_position(at_position)
	
	if drop_section in [-1, 0, 1]:
		return true
	
	drop_mode_flags = Tree.DROP_MODE_DISABLED
	return false


func _drop_data(at_position: Vector2, drop_data: Variant) -> void:
	var drop_section := get_drop_section_at_position(at_position)
	var item_at_position := get_item_at_position(at_position)
	drop_mode_flags = Tree.DROP_MODE_DISABLED
	if not item_at_position:
		Debug.print_error_message("Error on drop")
		return
	items_dropped.emit(drop_data.type, drop_data.items, item_at_position, drop_section)
