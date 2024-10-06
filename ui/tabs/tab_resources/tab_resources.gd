class_name TabResources
extends Control


const DIRECTORY_ICON = preload("res://resources/icons/directory_icon.png")
const TEXTURE_ICON = preload("res://resources/icons/texture_icon.png")
const SOUND_ICON = preload("res://resources/icons/sound_icon.png")
const FILE_ICON = preload("res://resources/icons/file_icon.png")


var root: TreeItem
var resources := {}


@onready var tree: DraggableTree = %DraggableTree


func _ready() -> void:
	tree.item_mouse_selected.connect(_on_item_mouse_selected)
	

func add_resource(parent: TreeItem, resource: CampaignResource) -> TreeItem:
	var resource_item := parent.create_child()
	
	match resource.type:
		ResourceType.DIRECTORY:
			resource_item.set_icon(0, DIRECTORY_ICON)
		ResourceType.TEXTURE:
			resource_item.set_icon(0, TEXTURE_ICON)
		ResourceType.SOUND:
			resource_item.set_icon(0, SOUND_ICON)
		ResourceType.FILE:
			resource_item.set_icon(0, FILE_ICON)
		
	resource_item.set_text(0, resource.path.get_file().get_basename())
	resource_item.set_tooltip_text(0, resource.path)
	resource_item.set_metadata(0, resource)

	resources[resource.path] = resource_item
	return resource_item


func _on_item_mouse_selected(_mouse_position: Vector2, mouse_button_index: int):
	var item_selected := tree.get_selected()
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		var resource: CampaignResource = item_selected.get_metadata(0)
		DisplayServer.clipboard_set(resource.path)
		
		var copied := Button.new()
		get_tree().root.add_child(copied)
		get_tree().create_timer(1).timeout.connect(copied.queue_free)
		copied.text = "Copied!"
		copied.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copied.position = get_viewport().get_mouse_position()
		


func _on_items_moved(items: Array[TreeItem], index: int):
	if not items:
		return
	

func reset() -> void:
	var init_time := Time.get_ticks_msec() / 1000.0
	
	resources.clear()
	tree.clear()
	root = tree.create_item()
	root.set_icon(0, DIRECTORY_ICON)
	root.set_text(0, "Resources")
	
	if not Game.is_master: return
	if not Game.campaign: return
	
	walk_dirs(root, Game.campaign.resources_path)
	
	var total_time := Time.get_ticks_msec() / 1000.0 - init_time
	Debug.print_info_message("Resources loaded in %s seconds" % snappedf(total_time, 0.001))


func walk_dirs(parent: TreeItem, path: String):
	var resource_type := ResourceType.DIRECTORY
	var relative_path: String = path.substr(len(Game.campaign.resources_path) + 1)
	for dir in DirAccess.get_directories_at(path):
		var resource_item := add_resource(parent, CampaignResource.new(resource_type, relative_path.path_join(dir)))
		resource_item.collapsed = true
		
		walk_dirs(resource_item, path.path_join(dir))
		
	for file in DirAccess.get_files_at(path):
		match file.get_extension().to_lower():
			"png": resource_type = ResourceType.TEXTURE
			"mp3": resource_type = ResourceType.SOUND
			_: resource_type = ResourceType.FILE
		var resource_item := add_resource(parent, CampaignResource.new(resource_type, relative_path.path_join(file)))


class ResourceType:
	const DIRECTORY = "directory"
	const TEXTURE = "texture"
	const SOUND = "sound"
	const FILE = "file"


class CampaignResource:
	var type: String
	var path: String
	
	func _init(_type: String, _path: String) -> void:
		type = _type
		path = _path
