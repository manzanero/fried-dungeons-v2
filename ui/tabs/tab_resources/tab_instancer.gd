class_name TabInstancer
extends Control

const DIRECTORY_ICON = preload("res://resources/icons/directory_icon.png")
const TEXTURE_ICON = preload("res://resources/icons/texture_icon.png")
const SOUND_ICON = preload("res://resources/icons/sound_icon.png")
const FILE_ICON = preload("res://resources/icons/file_icon.png")


var root: TreeItem
var item_selected: TreeItem
var resource_selected: CampaignResource :
	get: 
		if not item_selected: return
		if item_selected == root: return
		return item_selected.get_metadata(0)

var resources := {}
var resource_items := {}
var items_collapsed := {}

@onready var scan_button: Button = %ScanButton
@onready var folder_button: Button = %FolderButton

@onready var entity_button: Button = %EntityButton
@onready var light_button: Button = %LightButton
@onready var shape_button: Button = %ShapeButton

@onready var tree: DraggableTree = %DraggableTree

@onready var texture_container: ImportTexture = %ImportTexture


func _ready() -> void:
	scan_button.pressed.connect(reset)
	folder_button.pressed.connect(_on_folder_button_pressed)
	
	entity_button.pressed.connect(_on_instance_button_pressed.bind(entity_button, LevelBuildingState.NEW_ENTITY))
	light_button.pressed.connect(_on_instance_button_pressed.bind(light_button, LevelBuildingState.NEW_LIGHT))
	shape_button.pressed.connect(_on_instance_button_pressed.bind(shape_button, LevelBuildingState.NEW_SHAPE))
	visibility_changed.connect(_on_visibility_changed)
	
	tree.item_mouse_selected.connect(_on_item_mouse_selected)
	tree.item_activated.connect(_on_item_activated)
	tree.item_collapsed.connect(_on_item_collapsed)
	texture_container.visible = false
	texture_container.resource_changed.connect(_on_resource_changed)


func _on_folder_button_pressed() -> void:
	item_selected = tree.get_selected()
	if not is_instance_valid(item_selected) or item_selected == root: 
		Utils.open_in_file_manager(Game.campaign.resources_path)
		return
	
	var resource = item_selected.get_metadata(0); if not resource: return
	match resource.type:
		CampaignResource.Type.DIRECTORY: Utils.open_in_file_manager(resource.abspath)
		_: Utils.open_in_file_manager(resource.abspath.get_base_dir())


func _on_instance_button_pressed(button: Button, mode: int) -> void:
	var state_machine := Game.ui.selected_map.selected_level.state_machine
	if button.button_pressed:
		state_machine.get_state_node("Building").mode = mode
		state_machine.change_state("Building")
	else:
		state_machine.change_state("Idle")


func _on_visibility_changed():
	item_selected = null
	tree.deselect_all()
	
	if not Game.ui.selected_map:
		return
	
	var state_machine := Game.ui.selected_map.selected_level.state_machine
	if not visible:
		if state_machine.state == "Building":
			state_machine.change_state("Idle")
			Utils.reset_button_group(entity_button.button_group)
		
		
func add_resource(parent: TreeItem, resource: CampaignResource) -> TreeItem:
	var resource_item := parent.create_child()
	
	match resource.type:
		CampaignResource.Type.DIRECTORY:
			resource_item.set_icon(0, DIRECTORY_ICON)
			resource_item.set_text(0, resource.path.get_file())
		CampaignResource.Type.TEXTURE:
			resource_item.set_icon(0, TEXTURE_ICON)
			resource_item.set_text(0, resource.path.get_file().get_basename())
		CampaignResource.Type.SOUND:
			resource_item.set_icon(0, SOUND_ICON)
			resource_item.set_text(0, resource.path.get_file().get_basename())
		_:
			resource_item.set_icon(0, FILE_ICON)
			resource_item.set_text(0, resource.path.get_file())
	
	resource_item.set_tooltip_text(0, resource.path)
	resource_item.set_metadata(0, resource)

	resource_items[resource.path] = resource_item
	resources[resource.path] = resource
	resource.loaded = true
	return resource_item


func _on_item_mouse_selected(_mouse_position: Vector2, mouse_button_index: int):
	item_selected = tree.get_selected()
	if item_selected == root: 
		return
		
	var resource = item_selected.get_metadata(0)
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		DisplayServer.clipboard_set(resource.path)
		Utils.temp_tooltip("Copied!", 1)


func _on_item_collapsed(item: TreeItem):
	var resource: CampaignResource = item.get_metadata(0)
	if resource and resource.type == CampaignResource.Type.DIRECTORY: 
		items_collapsed[resource.path] = item.collapsed


func _on_item_activated():
	item_selected = tree.get_selected()
	if item_selected == root:
		item_selected.collapsed = not item_selected.collapsed
		return
	
	# may be for a previous scan
	if not is_instance_valid(item_selected):
		return
	
	var resource: CampaignResource = item_selected.get_metadata(0)
	Debug.print_info_message("Resource \"%s\" activated" % resource.path)
	
	match resource.type:
		CampaignResource.Type.DIRECTORY: 
			item_selected.collapsed = not item_selected.collapsed
		CampaignResource.Type.TEXTURE:
			texture_container.visible = true
			texture_container.resource = resource
		CampaignResource.Type.SOUND:
			texture_container.visible = false
		_:
			texture_container.visible = false
		


func _on_items_moved(items: Array[TreeItem], index: int):
	if not items:
		return
	

func reset() -> void:
	var init_time := Time.get_ticks_msec() / 1000.0
	
	tree.clear()
	root = tree.create_item()
	root.set_icon(0, DIRECTORY_ICON)
	root.set_text(0, "Resources")
	root.set_tooltip_text(0, "")
	
	Utils.make_dirs(Game.campaign.resources_path)
	walk_dirs(root, Game.campaign.resources_path)
	
	var total_time := Time.get_ticks_msec() / 1000.0 - init_time
	Debug.print_info_message("Resources loaded in %s seconds" % snappedf(total_time, 0.001))


func walk_dirs(parent: TreeItem, path: String):
	var resource_type := CampaignResource.Type.DIRECTORY
	var relative_path: String = path.substr(len(Game.campaign.resources_path) + 1)
	for dir in DirAccess.get_directories_at(path):
		var resource_path := relative_path.path_join(dir)
		var resource: CampaignResource = resources.get(resource_path)
		if not resource: 
			resource = CampaignResource.new(resource_type, resource_path)
			
		var resource_item := add_resource(parent, resource)
		resource_item.collapsed = items_collapsed.get(resource.path, true)
		
		walk_dirs(resource_item, path.path_join(dir))
		
	for file in DirAccess.get_files_at(path):
		match file.get_extension().to_lower():
			"png": resource_type = CampaignResource.Type.TEXTURE
			"ogg","mp3": resource_type = CampaignResource.Type.SOUND
			_: resource_type = CampaignResource.Type.FILE
		
		var resource_path := relative_path.path_join(file)
		var resource: CampaignResource = resources.get(resource_path)
		if not resource: 
			var import_data: Dictionary = Game.campaign.imports.get(resource_path, {})
			resource = CampaignResource.new(resource_type, resource_path, import_data)
			
		add_resource(parent, resource)


func _on_resource_changed(resource: CampaignResource) -> void:
	Game.campaign.imports[resource.path] = resource.import_data