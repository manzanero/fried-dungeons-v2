class_name CampaignBlueprint
extends Resource


signal blueprint_changed
signal blueprint_removed


class Type:
	const FOLDER = "folder"
	const LIGHT = "light"
	const ENTITY = "entity"
	const PROP = "prop"
	const EMPTY = "empty"

const types := [Type.FOLDER, Type.LIGHT, Type.ENTITY, Type.PROP]

var id: String

func get_children() -> Array[CampaignBlueprint]:
	var children: Array[CampaignBlueprint] = []
	var blueprint_item: TreeItem = Game.ui.tab_blueprints.blueprint_items[id]
	for child in blueprint_item.get_children():
		children.append(TabBlueprints.get_item_blueprint(child))
	return children

var path: String :
	get: return Game.ui.tab_blueprints.get_tree_path(id)

var name: String :
	get: return Game.ui.tab_blueprints.blueprint_items[id].get_text(0)
	
var type: String
var properties: Dictionary

var is_folder: bool :
	get: return type == CampaignBlueprint.Type.FOLDER

var abspath: String :
	get: return Game.campaign.get_blueprint_abspath(path)
			
var exists: bool :
	get: return Game.campaign.blueprint_exists(path)


func set_property(property_name: String, property_value: Variant):
	properties[property_name] = property_value
	blueprint_changed.emit()


func _init(_type: String, _id: String, _properties := {}) -> void:
	type = _type
	id = _id
	set_raw_properties(_properties)


func get_raw_properties() -> Dictionary:
	match type:
		"light": return Light.parse_property_values(properties)
		"entity": return Entity.parse_property_values(properties)
		"prop": return Prop.parse_property_values(properties)
		_: return {}


func set_raw_properties(raw_properties: Dictionary) -> void:
	var parsed_properties := parse_raw_properties(raw_properties)
	for property_name in parsed_properties:
		var property_value: Variant = parsed_properties[property_name]
		if properties.get(property_name) != property_value:
			set_property(property_name, property_value)


func parse_raw_properties(raw_properties: Dictionary) -> Dictionary:
	match type:
		"light": return Light.parse_raw_property_values(raw_properties)
		"entity": return Entity.parse_raw_property_values(raw_properties)
		"prop": return Prop.parse_raw_property_values(raw_properties)
		_: return {}


#func _set_path(value):
	#for child in get_children():
		#child.path = child.path.replace(path, value)
	#path = value


func remove() -> void:
	Debug.print_info_message("Removing blueprint: %s" % path)
		
	for child in get_children():
		child.remove()
	
	Utils.remove_dirs(abspath)

	blueprint_removed.emit()


func json() -> Dictionary:
	return {
		"type": type,
		"id": id,
		"properties": get_raw_properties(),
	}
