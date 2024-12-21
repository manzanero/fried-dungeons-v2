class_name Player
extends Resource


@export var slug := "Unnamed"
@export var username := "Unnamed"
@export var color := Color.BLUE
@export var entities := {}


func _init(_slug: String, _data: Dictionary):
	slug = _slug
	username = _data.username
	color = Utils.html_color_to_color(_data.color) if _data.has("color") else Color.WHITE
	entities = _data.get("entities", {})


func json():
	return {
		"username": username,
		"color": Utils.color_to_html_color(color),
		"entities": entities,
	}
