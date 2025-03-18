class_name TabResources
extends Control

const DIRECTORY_ICON = preload("res://resources/icons/directory_icon.png")
const OPEN_FOLDER_ICON = preload("res://resources/icons/open_folder_icon.png")
const TEXTURE_ICON = preload("res://resources/icons/texture_icon.png")
const SOUND_ICON = preload("res://resources/icons/sound_icon.png")
const FILE_ICON = preload("res://resources/icons/file_icon.png")
const EDIT_ICON = preload("res://resources/icons/edit_icon.png")

var root: TreeItem
var item_selected: TreeItem :
	get: return tree.get_selected()

var resource_selected: CampaignResource :
	get: 
		if not item_selected: 
			return
		if item_selected == root: 
			return
		return item_selected.get_metadata(0)

var resource_items := {}
var items_collapsed := {}

var orphan_resource_data := []

@onready var scan_button: Button = %ScanButton
@onready var folder_button: Button = %FolderButton
@onready var label_line_edit: LineEdit = %LabelLineEdit

#@onready var entity_button: Button = %EntityButton
#@onready var light_button: Button = %LightButton
#@onready var shape_button: Button = %ShapeButton

@onready var tree: DraggableTree = %DraggableTree

@onready var texture_container: ImportTexture = %ImportTexture
@onready var sound_container: ImportSound = %ImportSound


func _ready() -> void:
	scan_button.pressed.connect(reset)
	folder_button.pressed.connect(_on_folder_button_pressed)
	label_line_edit.text_changed.connect(_on_label_filter_changed.unbind(1))
	
	visibility_changed.connect(_on_visibility_changed)
	
	tree.item_mouse_selected.connect(_on_item_mouse_selected)
	tree.item_activated.connect(_on_item_activated)
	tree.button_clicked.connect(_on_button_clicked)
	tree.item_collapsed.connect(_on_item_collapsed)
	texture_container.visible = false
	texture_container.attributes_changed.connect(_on_attributes_changed)
	sound_container.visible = false
	sound_container.attributes_changed.connect(_on_attributes_changed)


func _on_folder_button_pressed() -> void:
	item_selected = tree.get_selected()
	if not is_instance_valid(item_selected) or item_selected == root: 
		Utils.open_in_file_manager(Game.campaign.resources_path)
		return
	
	var resource = item_selected.get_metadata(0); if not resource: return
	match resource.resource_type:
		CampaignResource.Type.DIRECTORY: Utils.open_in_file_manager(resource.abspath)
		_: Utils.open_in_file_manager(resource.abspath.get_base_dir())
	

func _on_label_filter_changed():
	var visibles: Array[TreeItem] = [root]
	var filter := label_line_edit.text.to_lower()
	for item: TreeItem in resource_items.values():
		var label := item.get_text(0)
		if filter and filter not in label.to_lower():
			item.visible = false
		else:
			item.visible = true
			visibles.append(item)
			var parent := item.get_parent()
			while parent not in visibles:
				parent.visible = true
				parent = parent.get_parent()
	root.visible = true


func _on_visibility_changed():
	tree.deselect_all()
		
		
func add_resource(parent: TreeItem, resource: CampaignResource) -> TreeItem:
	var resource_item := parent.create_child()
	
	match resource.resource_type:
		CampaignResource.Type.DIRECTORY:
			resource_item.set_icon(0, DIRECTORY_ICON)
			resource_item.set_text(0, resource.path.get_file())
			resource_item.add_button(0, OPEN_FOLDER_ICON, 0)
			resource_item.set_button_color(0, 0, Game.TREE_BUTTON_OFF_COLOR)
		CampaignResource.Type.TEXTURE:
			resource_item.set_icon(0, TEXTURE_ICON)
			resource_item.set_text(0, resource.path.get_file().get_basename())
			resource_item.add_button(0, EDIT_ICON, 0)
			resource_item.set_button_color(0, 0, Game.TREE_BUTTON_OFF_COLOR)
			resource_item.add_button(0, OPEN_FOLDER_ICON, 1)
			resource_item.set_button_color(0, 1, Game.TREE_BUTTON_OFF_COLOR)
		CampaignResource.Type.SOUND:
			resource_item.set_icon(0, SOUND_ICON)
			resource_item.set_text(0, resource.path.get_file().get_basename())
			resource_item.add_button(0, EDIT_ICON, 0)
			resource_item.set_button_color(0, 0, Game.TREE_BUTTON_OFF_COLOR)
			resource_item.add_button(0, OPEN_FOLDER_ICON, 1)
			resource_item.set_button_color(0, 1, Game.TREE_BUTTON_OFF_COLOR)
		_:
			resource_item.set_icon(0, FILE_ICON)
			resource_item.set_text(0, resource.path.get_file())
			resource_item.add_button(0, OPEN_FOLDER_ICON, 0)
			resource_item.set_button_color(0, 0, Game.TREE_BUTTON_OFF_COLOR)
	
	resource_item.set_tooltip_text(0, resource.path)
	resource_item.set_metadata(0, resource)
	
	resource_items[resource.path] = resource_item
	return resource_item


func _on_item_mouse_selected(_mouse_position: Vector2, mouse_button_index: int):
	item_selected = tree.get_selected()
	if item_selected == root: 
		return
		
	var resource = item_selected.get_metadata(0)
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		DisplayServer.clipboard_set(resource.path)
		Utils.temp_info_tooltip("Copied!", 1)


func _on_item_collapsed(item: TreeItem):
	var resource: CampaignResource = item.get_metadata(0)
	if resource and resource.resource_type == CampaignResource.Type.DIRECTORY: 
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
	
	#var is_activated := item_selected.get_custom_color(0) == Color.GREEN
	
	for item in resource_items.values():
		item.clear_custom_color(0)
	#if not is_activated and resource.resource_type != CampaignResource.Type.DIRECTORY: 
		#item_selected.set_custom_color(0, Color.GREEN)
	item_selected.set_custom_color(0, Color.GREEN)
	
	texture_container.visible = false
	texture_container.resource = null
	sound_container.visible = false
	sound_container.resource = null
	
	#if is_activated:
		#return
		
	match resource.resource_type:
		CampaignResource.Type.DIRECTORY: 
			item_selected.collapsed = not item_selected.collapsed
		CampaignResource.Type.TEXTURE:
			texture_container.visible = true
			texture_container.resource = resource
		CampaignResource.Type.SOUND:
			sound_container.visible = true
			sound_container.resource = resource


func _on_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
	var resource: CampaignResource = item.get_metadata(0)
	item.select(0)
	
	if item == root:
		_on_folder_button_pressed()
		return

	match resource.resource_type:
		CampaignResource.Type.DIRECTORY: 
			_on_folder_button_pressed()
		CampaignResource.Type.TEXTURE:
			if id == 0:
				_on_item_activated()
			else:
				_on_folder_button_pressed()
		CampaignResource.Type.SOUND:
			if id == 0:
				_on_item_activated()
			else:
				_on_folder_button_pressed()


func _on_items_moved(items: Array[TreeItem], _index: int):
	if not items:
		return
	

func reset() -> void:
	sound_container.visible = false
	texture_container.visible = false
	
	resource_items.clear()
	tree.clear()
	root = tree.create_item()
	root.set_icon(0, DIRECTORY_ICON)
	root.set_text(0, "Resources")
	root.add_button(0, OPEN_FOLDER_ICON)
	root.set_button_color(0, 0, Game.TREE_BUTTON_OFF_COLOR)
	root.set_tooltip_text(0, " ")
	
	if not Game.campaign:
		return
		
	var init_time := Time.get_ticks_msec() / 1000.0
	
	Utils.make_dirs(Game.campaign.resources_path)
	walk_dirs(root, Game.campaign.resources_path)
	
	var total_time := Time.get_ticks_msec() / 1000.0 - init_time
	Debug.print_info_message("Resources loaded in %s seconds" % snappedf(total_time, 0.001))


func walk_dirs(parent: TreeItem, path: String):
	var resource_type := CampaignResource.Type.DIRECTORY
	var relative_path: String = path.substr(len(Game.campaign.resources_path) + 1)
	for dir in DirAccess.get_directories_at(path):
		var resource_path := relative_path.path_join(dir)
		var resource: CampaignResource = Game.resources.get(resource_path)
		if not resource: 
			resource = CampaignResource.new(resource_type, resource_path)
			
		var resource_item := add_resource(parent, resource)
		resource_item.collapsed = items_collapsed.get(resource.path, true)
		
		walk_dirs(resource_item, path.path_join(dir))
	
	var files := DirAccess.get_files_at(path)
	for file in files:
		var file_path := path.path_join(file)
		match file.get_extension().to_lower():
			"png": resource_type = CampaignResource.Type.TEXTURE
			"ogg","mp3": resource_type = CampaignResource.Type.SOUND
			"json": 
				if not file.get_basename() in files:
					Utils.remove_file(file_path)
				continue
			_: resource_type = CampaignResource.Type.FILE
		
		var resource_path := relative_path.path_join(file)
		var timestamp := FileAccess.get_modified_time(file_path)
		
		# check if resource is already loaded to preserve connected signals
		# at the beginning this is always empty
		var resource: CampaignResource = Game.resources.get(resource_path)
		if not resource:
			var import_data := Game.campaign.get_resource_data(resource_path)
			resource = CampaignResource.new(resource_type, resource_path, import_data)
			
			# missing data file for resource
			if not import_data:
				Game.campaign.set_resource_data(resource_path, resource.json())
		
		 # resource has been updated
		if resource.timestamp < timestamp:
			resource.timestamp = timestamp
			resource.resource_changed.emit()
			Game.campaign.set_resource_data(resource_path, resource.json())
		
			if multiplayer.is_server():
				Game.server.resource_change_notification.rpc(resource.path)
		
		Game.campaign.resources[resource.path] = timestamp
		Game.resources[resource.path] = resource
			
		resource.resource_loaded = true
		add_resource(parent, resource)


func _on_attributes_changed(resource: CampaignResource, import_as: String, attributes: Dictionary) -> void:
	resource.resource_import_as = import_as
	resource.attributes = attributes
	Game.campaign.set_resource_data(resource.path, resource.json())
