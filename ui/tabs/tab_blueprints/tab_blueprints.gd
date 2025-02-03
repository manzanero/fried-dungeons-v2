class_name TabBlueprints
extends Control

const DIRECTORY_ICON = preload("res://resources/icons/directory_icon.png")
const GODOT_ICON = preload("res://resources/icons/godot_icon.png")

var map: Map :
	get: return Game.ui.selected_map
var level: Level :
	get: return map.selected_level

var root: TreeItem

var item_selected: TreeItem :
	get: return tree.get_selected()
	
func get_item_blueprint(item: TreeItem) -> CampaignBlueprint:
	return item.get_metadata(0) if is_instance_valid(item) and item != root else null

var blueprint_selected: CampaignBlueprint :
	get: 
		if not item_selected: 
			return
		if item_selected == root: 
			return
		return get_item_blueprint(item_selected)

var blueprint_items := {}
var items_collapsed := {}
var path_selected: String

var orphan_bluepint_data := []

@onready var new_button: MenuButton = %NewButton
@onready var folder_button: Button = %FolderButton
@onready var scan_button: Button = %ScanButton

@onready var tree: DraggableTree = %DraggableTree

@onready var instance_button: Button = %InstanceButton
@onready var duplicate_button: Button = %DuplicateButton
@onready var remove_button: Button = %RemoveButton


func _ready() -> void:
	var new_popup := new_button.get_popup()
	new_popup.get_window().transparent = true
	new_popup.id_pressed.connect(_on_new_popup_id_pressed_pressed)
	folder_button.pressed.connect(_on_folder_button_pressed)
	scan_button.pressed.connect(reset)
	
	instance_button.pressed.connect(_on_instance_button_pressed)
	duplicate_button.pressed.connect(_on_duplicate_button_pressed)
	remove_button.pressed.connect(_on_remove_button_pressed)
	
	visibility_changed.connect(_on_visibility_changed)
	
	tree.item_selected.connect(_on_item_selected)
	tree.item_mouse_selected.connect(_on_item_mouse_selected)
	tree.item_activated.connect(_on_item_activated)
	tree.item_collapsed.connect(_on_item_collapsed)
	
	tree.drag_type = "campaign_blueprint_items"


func _on_new_popup_id_pressed_pressed(id: int) -> void:
	print(id)


func _on_folder_button_pressed() -> void:
	item_selected = tree.get_selected()
	if not is_instance_valid(item_selected) or item_selected == root: 
		Utils.open_in_file_manager(Game.campaign.blueprints_path)
		return
	
	var blueprint: CampaignBlueprint = item_selected.get_metadata(0); if not blueprint: return
	match blueprint.type:
		CampaignBlueprint.Type.DIRECTORY: 
			Utils.open_in_file_manager(blueprint.abspath)
		_: 
			Utils.open_in_file_manager(blueprint.abspath.get_base_dir())


func _on_visibility_changed():
	#tree.deselect_all()
	if root:
		root.select(0)
		
		
func add_blueprint(parent: TreeItem, blueprint: CampaignBlueprint) -> TreeItem:
	var blueprint_item := parent.create_child()
	
	match blueprint.type:
		CampaignBlueprint.Type.DIRECTORY:
			blueprint_item.set_icon(0, DIRECTORY_ICON)
			blueprint_item.set_text(0, blueprint.path.get_file())
		_:
			blueprint_item.set_icon(0, GODOT_ICON)
			blueprint_item.set_text(0, blueprint.path.get_file().get_basename())
	
	blueprint_item.set_tooltip_text(0, blueprint.path)
	blueprint_item.set_metadata(0, blueprint)
	
	blueprint_items[blueprint.path] = blueprint_item
	Game.blueprints[blueprint.path] = blueprint
	
	return blueprint_item


func _on_item_selected():
	if blueprint_selected:
		path_selected = blueprint_selected.path
		print(path_selected)
	else:
		path_selected = ""


func _on_item_mouse_selected(_mouse_position: Vector2, mouse_button_index: int):
	item_selected = tree.get_selected()
	if item_selected == root: 
		return
		
	var blueprint = item_selected.get_metadata(0)
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		DisplayServer.clipboard_set(blueprint.path)
		Utils.temp_info_tooltip("Copied!", 1)


func _on_item_collapsed(item: TreeItem):
	var blueprint: CampaignBlueprint = item.get_metadata(0)
	if blueprint and blueprint.type == CampaignBlueprint.Type.DIRECTORY: 
		items_collapsed[blueprint.path] = item.collapsed


func _on_item_activated():
	item_selected = tree.get_selected()
	if item_selected == root:
		item_selected.collapsed = not item_selected.collapsed
		return
	
	var blueprint: CampaignBlueprint = item_selected.get_metadata(0)
	Debug.print_info_message("Blueprint \"%s\" activated" % blueprint.path)
	
	match blueprint.type:
		CampaignBlueprint.Type.DIRECTORY:
			item_selected.collapsed = not item_selected.collapsed
	
		CampaignBlueprint.Type.ENTITY:
			Game.modes.change_mode(ModeController.Mode.ENTITY_3D_SHAPE)
			level.state_machine.get_state_node(Level.State.GO_ELEMENT_INSTANCING).preview_blueprint = blueprint


func _on_items_moved(items: Array[TreeItem], _index: int):
	if not items:
		return
	

func reset() -> void:
	if not Game.campaign or not Game.campaign.is_master:
		return
		
	blueprint_items.clear()
	tree.clear()
	root = tree.create_item()
	root.set_icon(0, DIRECTORY_ICON)
	root.set_text(0, "Blueprints")
	root.set_tooltip_text(0, " ")
	walk_dirs(root, Game.campaign.blueprints_path)
	
	if blueprint_items.has(path_selected):
		blueprint_items[path_selected].select(0)
	else:
		root.select(0)
	
	Utils.temp_info_tooltip("Blueprints reloaded")


func walk_dirs(parent: TreeItem, path: String):
	var blueprint_type := CampaignBlueprint.Type.DIRECTORY
	var relative_path: String = path.substr(len(Game.campaign.blueprints_path) + 1)
	for dir in DirAccess.get_directories_at(path):
		var blueprint_path := relative_path.path_join(dir)
		var blueprint: CampaignBlueprint = Game.blueprints.get(blueprint_path)
		if not blueprint: 
			blueprint = CampaignBlueprint.new(blueprint_type, blueprint_path)
			
		var blueprint_item := add_blueprint(parent, blueprint)
		blueprint_item.collapsed = items_collapsed.get(blueprint.path, true)
		
		walk_dirs(blueprint_item, path.path_join(dir))
	
	var files := DirAccess.get_files_at(path)
	for file in files:
		var blueprint_path := relative_path.path_join(file).get_basename()
		var blueprint: CampaignBlueprint = Game.blueprints.get(blueprint_path)
		var blueprint_data := Game.campaign.get_blueprint_data(blueprint_path)
		var blueprint_raw_properties: Dictionary = blueprint_data.get("properties", {})
		blueprint_type = blueprint_data.get("type", CampaignBlueprint.Type.EMPTY)
		if blueprint:
			blueprint.type = blueprint_type
			blueprint.set_raw_properties(blueprint_raw_properties)
		else:
			blueprint = CampaignBlueprint.new(blueprint_type, blueprint_path, blueprint_raw_properties)
		
		add_blueprint(parent, blueprint)


func _on_instance_button_pressed():
	var blueprint := blueprint_selected
	if not blueprint:
		Utils.temp_error_tooltip("Select a Blueprint")
		return
	
	_on_item_activated()


func _on_duplicate_button_pressed():
	var blueprint := blueprint_selected
	if not blueprint:
		Utils.temp_error_tooltip("Cannot duplicate a folder")
		return
	
	save_new(blueprint.type, blueprint.file_name, blueprint.get_raw_properties())


func _on_remove_button_pressed():
	var item := item_selected
	var blueprint := blueprint_selected
	if not blueprint:
		Utils.temp_error_tooltip("Select a Blueprint")
		return
	
	var new_item_selected := item.get_prev_visible()
	if not new_item_selected:
		new_item_selected = item.get_parent()
	
	new_item_selected.select(0)
	
	if blueprint.type == CampaignBlueprint.Type.DIRECTORY:
		var blueprint_paths := blueprint_items.keys()
		blueprint_paths.reverse()
		for blueprint_path: String in blueprint_paths:
			if blueprint_path.begins_with(blueprint.path):
				var blueprint_item: TreeItem = blueprint_items[blueprint_path]
				var blueprint_to_remove := get_item_blueprint(blueprint_item)
				
				blueprint_to_remove.remove()
				blueprint_items.erase(blueprint_path)
				blueprint_item.free()
				
		Utils.temp_info_tooltip("Folder %s removed" % blueprint.path)
		
	else:
		blueprint.remove()
		blueprint_items.erase(blueprint.path)
		item.free()
		
		Utils.temp_info_tooltip("Blueprint %s removed" % blueprint.path)


func save_new(type: String, blueprint_name: String, raw_properties: Dictionary) -> CampaignBlueprint:
	var blueprint_basedir: String = Utils.get_tree_path(item_selected)
	if not item_selected or item_selected == root:
		blueprint_basedir = ""
	elif blueprint_selected.type == CampaignBlueprint.Type.DIRECTORY:
		blueprint_basedir = Utils.get_tree_path(item_selected)
	else:
		blueprint_basedir = Utils.get_tree_path(item_selected.get_parent())
	
	var blueprint_path = blueprint_basedir.path_join(blueprint_name)
	var blueprint_abspath = Game.campaign.get_blueprint_file_abspath(blueprint_path)
	var siblings := Utils.file_siblings_count(blueprint_abspath)
	if siblings > 0:
		blueprint_path = "%s %s" % [blueprint_path, siblings + 1]
		
	Game.campaign.set_blueprint_data(blueprint_path, {"type": type, "properties": raw_properties})
	
	var blueprint: = CampaignBlueprint.new(type, blueprint_path, raw_properties)
	var blueprint_item: TreeItem
	if not item_selected or item_selected == root:
		blueprint_item = add_blueprint(root, blueprint)
	elif blueprint_selected.type == CampaignBlueprint.Type.DIRECTORY:
		blueprint_item = add_blueprint(item_selected, blueprint)
	else:
		blueprint_item = add_blueprint(item_selected.get_parent(), blueprint)
	
	#reset()
	sort_children(blueprint_item.get_parent())
	blueprint_item.select(0)
	
	return blueprint


func sort_children(item: TreeItem):
	var sorted_children := item.get_children()
	sorted_children.sort_custom(func(a: TreeItem, b: TreeItem): 
		return a.get_text(0).naturalnocasecmp_to(b.get_text(0)) < 0
	)

	for child in item.get_children():
		item.remove_child(child)

	for child in sorted_children:
		item.add_child(child)
	
	
