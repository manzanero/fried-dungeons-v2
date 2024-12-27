class_name Player
extends Resource


var slug := "unnamed"
var username := "Unnamed"
var color := Color.BLUE
var elements := {}


func _init(_slug: String, _data: Dictionary):
	slug = _slug
	username = _data.username
	color = Utils.html_color_to_color(_data.color) if _data.has("color") else Color.WHITE
	elements = _data.get("elements", {})
	

func set_element_control(element_id: String, control_data := {}):
	elements[element_id] = control_data
	

func get_permission(entity_id: String, permission: String) -> bool:
	if not elements.has(entity_id): 
		return false
	return elements[entity_id].get(permission, false)


func set_permission(entity_id: String, permission: String, is_allowed: bool) -> void:
	if not elements.has(entity_id):
		elements[entity_id] = {}
	elements[entity_id][permission] = is_allowed


class Permission:
	const MOVEMENT := "movement"
	const SENSES := "senses"


func json():
	return {
		"username": username,
		"color": Utils.color_to_html_color(color),
		#"entities": entities,
	}
