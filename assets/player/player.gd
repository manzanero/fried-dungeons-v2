class_name Player
extends Resource


@export var username := "Unnamed"
@export var password := ""
@export var color := Color.BLUE
@export var entities := {}


func _init(_username := username, _password := password, _color := color, _entities := entities) -> void:
	username = _username
	password = _password
	color = _color
	entities = _entities
	

var slug: String :
	get:
		return Utils.slugify(username)


static func load(player_data: Dictionary) -> Player:
	return Player.new(player_data.username, player_data.password, 
			Utils.html_color_to_color(player_data.get("color", "FFFFFF")), 
			player_data.get("entities", {}))


func json():
	return {
		"username": username,
		"password": password,
		"color": Utils.color_to_html_color(color),
		"entities": entities,
	}
