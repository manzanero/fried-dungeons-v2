class_name Player
extends Resource


var slug := "unnamed"
var username := "Unnamed"
var color := Color.BLUE
var elements := {}


func _init(_slug: String, _data: Dictionary):
	slug = _slug
	username = _data.username
	color = Color.WHITE
	if _data.has("color"):
		color = Utils.color_no_alpha(Utils.html_color_to_color(_data.color))
	elements = _data.get("elements", {})
	

func set_element_control(element_label: String, control_data := {}):
	elements[element_label] = control_data
	

func clear_element_control(element_label: String):
	elements.erase(element_label)
	

func get_permission(element_label: String, permission: String) -> bool:
	if not elements.has(element_label): 
		return false
	return elements[element_label].get(permission, false)


func set_permission(element_label: String, permission: String, is_allowed: bool) -> void:
	if not elements.has(element_label):
		elements[element_label] = {}
	elements[element_label][permission] = is_allowed


class Permission:
	const MOVEMENT := "movement"
	const SENSES := "senses"


func json():
	return {
		"username": username,
		"color": Utils.color_to_html_color(color),
		#"entities": entities,
	}
