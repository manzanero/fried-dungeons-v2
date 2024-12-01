class_name CampaignResource
extends Resource


signal resource_loaded
signal resource_changed


class Type:
	const DIRECTORY = "directory"
	const TEXTURE = "texture"
	const SOUND = "sound"
	const FILE = "file"

class ImportAs:
	# DIRECTORY
	const FOLDER = "folder"
	# TEXTURE
	const SLICED_SHAPE = "sliced_shape"
	const TEXTURE_INDEX = "texture_index"
	# SOUND
	const BACKGROUND_MUSIC = "background_music"
	const SOUND_EFFECT = "sound_effect"
	# FILE
	const ARCHIVE = "archive"

const DIRECTORY_IMPORTS := [ImportAs.FOLDER]
const TEXTURE_IMPORTS := [ImportAs.SLICED_SHAPE, ImportAs.TEXTURE_INDEX]
const SOUND_IMPORTS := [ImportAs.BACKGROUND_MUSIC, ImportAs.SOUND_EFFECT]
const FILE_IMPORTS := [ImportAs.ARCHIVE]


var loaded: bool :
	set(value): loaded = value; resource_loaded.emit()
var resource_type: String
var path: String
var timestamp: int :
	set(value): timestamp = value; resource_changed.emit()
var import_as: String :
	set(value): import_as = value; resource_changed.emit()
var attributes: Dictionary : 
	set(value): attributes = value; resource_changed.emit()


var abspath: String :
	get: return Game.campaign.get_resource_abspath(path)
var json_abspath: String :
	get: return abspath + ".json"


var extension: String :
	get: return path.get_extension()


var basename: String :
	get: return path.get_basename()


var file_basename: String :
	get: return path.get_file().get_basename()


func _init(_resource_type: String, _path: String, _import_data := {}) -> void:
	resource_type = _resource_type
	path = _path
		
	timestamp = _import_data.get("timestamp", 0)
	import_as = _import_data.get("import_as", "")
	if not import_as:
		match resource_type:
			Type.DIRECTORY: import_as = CampaignResource.DIRECTORY_IMPORTS[0]
			Type.TEXTURE: import_as = CampaignResource.TEXTURE_IMPORTS[0]
			Type.SOUND: import_as = CampaignResource.SOUND_IMPORTS[0]
			Type.FILE: import_as = CampaignResource.FILE_IMPORTS[0]
	attributes = _import_data.get("attributes", {})


func json():
	return {
		"timestamp": timestamp,
		"import_as": import_as,
		"attributes": attributes
	}
