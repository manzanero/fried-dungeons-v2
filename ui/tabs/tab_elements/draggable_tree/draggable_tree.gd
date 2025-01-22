class_name DraggableTree
extends Tree


signal items_dropped(items_data: Array[Dictionary], parent_item: TreeItem, item_index: int)


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
	
	var drop_section := get_drop_section_at_position(at_position)
	if drop_section == -1 and allow_drop_inbetween:
		drop_mode_flags = Tree.DROP_MODE_INBETWEEN
		return true
	elif drop_section == 0 and allow_drop_on_item:
		drop_mode_flags = Tree.DROP_MODE_ON_ITEM
		return true
	elif drop_section == 1 and allow_drop_inbetween:
		drop_mode_flags = Tree.DROP_MODE_INBETWEEN
		return true
	elif drop_section == -100 and allow_drop_blank:
		return true
		
	return false


func _drop_data(at_position: Vector2, drop_data: Variant) -> void:
	var drop_section := get_drop_section_at_position(at_position)
	var item := get_item_at_position(at_position)
		
	if drop_section == -1:
		items_dropped.emit(drop_data, item.get_parent(), item.get_index())
	elif drop_section == 0:
		items_dropped.emit(drop_data, item, -1)
	elif drop_section == 1:
		items_dropped.emit(drop_data, item.get_parent(), item.get_index() + 1)
	else:
		items_dropped.emit(drop_data, get_root(), -1)
		
	#for i in drop_items_data.size():
		#var item: TreeItem = items[i]
		#if drop_section == -1:
			#item.move_before(other_item)
		#elif drop_section == 1:
			#if i == 0:
				#item.move_after(other_item)
			#else:
				#item.move_after(items[i - 1])
