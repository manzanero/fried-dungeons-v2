class_name CampaignResource
extends Resource


signal loaded
signal resource_changed
signal resource_removed


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


var path: String
var resource_loaded: bool :
	set(value): resource_loaded = value; loaded.emit()
var resource_type: String
var resource_import_as: String :
	set(value): resource_import_as = value; resource_changed.emit()
var timestamp: int :
	set(value): timestamp = value; resource_changed.emit()
var attributes: Dictionary : 
	set(value): attributes = value; resource_changed.emit()


var abspath: String :
	get: return Game.campaign.get_resource_abspath(path)
var bytes: PackedByteArray :
	get: return FileAccess.get_file_as_bytes(abspath)
var file_exist: bool :
	get: return Game.campaign.resource_file_exists(path)
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
		
	timestamp = _import_data.get("timestamp", -1)
	resource_import_as = _import_data.get("import_as", "")
	if not resource_import_as:
		match resource_type:
			Type.DIRECTORY: resource_import_as = CampaignResource.DIRECTORY_IMPORTS[0]
			Type.TEXTURE: resource_import_as = CampaignResource.TEXTURE_IMPORTS[0]
			Type.SOUND: resource_import_as = CampaignResource.SOUND_IMPORTS[0]
			Type.FILE: resource_import_as = CampaignResource.FILE_IMPORTS[0]
	attributes = _import_data.get("attributes", {})


func update() -> CampaignResource:
	Debug.print_info_message("Updating resource: %s" % path)
	
	if not file_exist:
		Debug.print_info_message("Resource path not found: %s" % abspath)
		timestamp = -1

	Game.server.request_resource.rpc_id(1, path, timestamp)
	return self


func remove() -> void:
	Debug.print_info_message("Removing resource: %s" % path)
	
	resource_removed.emit(self)
	Utils.remove_file(abspath)
	Utils.remove_file(abspath + ".json")
	Game.campaign.resources.erase(path)


func json() -> Dictionary:
	return {
		"timestamp": timestamp,
		"type": resource_type,
		"import_as": resource_import_as,
		"attributes": attributes
	}
