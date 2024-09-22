class_name DraggableTree
extends Tree


signal items_moved(items: Array[TreeItem], other_item_index: int)


func _get_drag_data(_at_position: Vector2) -> Array[TreeItem]:
	var items: Array[TreeItem] = []
	var next: TreeItem = get_next_selected(null)
	var v := VBoxContainer.new()
	while next:
		items.append(next)
		var l := Label.new()
		l.text = next.get_text(0)
		v.add_child(l)
		next = get_next_selected(next)
	set_drag_preview(v)
	return items


func _can_drop_data(at_position: Vector2, items: Variant) -> bool:
	drop_mode_flags = Tree.DROP_MODE_INBETWEEN
	var drop_section := get_drop_section_at_position(at_position)
	if drop_section == -100:
		return false
	var item := get_item_at_position(at_position)
	if item in items:
		return false
	return true


func _drop_data(at_position: Vector2, items: Variant) -> void:
	var drop_section := get_drop_section_at_position(at_position)
	var other_item := get_item_at_position(at_position)
	if drop_section == -1:
		items_moved.emit(items, other_item.get_index())
	else:
		items_moved.emit(items, other_item.get_index() + 1)
		
	for i in items.size():
		var item: TreeItem = items[i]
		if drop_section == -1:
			item.move_before(other_item)
		elif drop_section == 1:
			if i == 0:
				item.move_after(other_item)
			else:
				item.move_after(items[i - 1])
