class_name CampaignResource
extends Resource


signal resource_loaded
signal resource_changed


class Type:
	const DIRECTORY = "directory"
	const TEXTURE = "texture"
	const SOUND = "sound"
	const FILE = "file"

var loaded: bool :
	set(value): loaded = value; resource_loaded.emit()
var type: String
var path: String
var import_data: Dictionary : 
	set(value): import_data = value; resource_changed.emit()


var abspath: String :
	get: return Game.campaign.resources_path.path_join(path)


var extension: String :
	get: return path.get_extension()


var basename: String :
	get: return path.get_basename()


var file_basename: String :
	get: return path.get_file().get_basename()


func _init(_type: String, _path: String, _import_data := {}) -> void:
	type = _type
	path = _path
	import_data = _import_data
