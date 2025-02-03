class_name CampaignBlueprint
extends Resource


signal blueprint_changed
signal blueprint_removed


class Type:
	const DIRECTORY = "directory"
	const LIGHT = "light"
	const ENTITY = "entity"
	const PROP = "prop"
	const EMPTY = "empty"

const types := [Type.DIRECTORY, Type.LIGHT, Type.ENTITY, Type.PROP]


var path: String
var type: String
var properties: Dictionary
#var properties: Dictionary : 
	#set(value): properties = value; blueprint_changed.emit()


var abspath: String :
	get: 
		if type == Type.DIRECTORY:
			return Game.campaign.get_blueprint_dir_abspath(path)
		else:
			return Game.campaign.get_blueprint_file_abspath(path)
			
var exists: bool :
	get: 
		if type == Type.DIRECTORY:
			return Game.campaign.blueprint_dir_exists(path)
		else:
			return Game.campaign.blueprint_file_exists(path)


var basename: String :
	get: 
		return path.get_basename()


var file_name: String :
	get: 
		return basename.get_file()
		

func set_property(property_name: String, property_value: Variant):
	properties[property_name] = property_value
	blueprint_changed.emit()


func _init(_type: String, _path: String, _properties := {}) -> void:
	type = _type
	path = _path
	set_raw_properties(_properties)


func get_raw_properties() -> Dictionary:
	match type:
		"light": return Light.parse_property_values(properties)
		"entity": return Entity.parse_property_values(properties)
		"prop": return Shape.parse_property_values(properties)
		_: return {}


func set_raw_properties(raw_properties: Dictionary) -> void:
	var parsed_properties
	match type:
		"light": parsed_properties = Light.parse_raw_property_values(raw_properties)
		"entity": parsed_properties = Entity.parse_raw_property_values(raw_properties)
		"prop": parsed_properties = Shape.parse_raw_property_values(raw_properties)
		_: return
	for property_name in parsed_properties:
		var property_value: Variant = parsed_properties[property_name]
		if properties.get(property_name) != property_value:
			set_property(property_name, property_value)


func remove() -> void:
	Debug.print_info_message("Removing blueprint: %s" % path)
	
	blueprint_removed.emit()
	if type == Type.DIRECTORY:
		Utils.remove_dir(abspath)
	else:
		Utils.remove_file(abspath)
	
	Game.blueprints.erase(path)


func json() -> Dictionary:
	return {
		"type": type,
		"properties": get_raw_properties(),
	}
