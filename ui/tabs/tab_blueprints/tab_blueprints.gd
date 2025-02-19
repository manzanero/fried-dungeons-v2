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
	get: 
		var item := tree.get_selected()
		return item if item else root
	
static func get_item_blueprint(item: TreeItem) -> CampaignBlueprint:
	return item.get_metadata(0) if is_instance_valid(item) else null

var blueprint_selected: CampaignBlueprint :
	get: return get_item_blueprint(item_selected)

var blueprint_items := {}  # id: TreeItem
var items_collapsed := {}  # TreeItem: bool
var items_selected := {}  # TreeItem: bool
#var current_item_selected: TreeItem
var current_item_path: String
var current_item_id: String

func get_tree_path(id: String) -> String:
	if not blueprint_items.has(id):
		return Game.NULL_STRING
	return Utils.get_tree_path(blueprint_items[id])

@onready var new_button: MenuButton = %NewButton
@onready var folder_button: Button = %FolderButton
@onready var scan_button: Button = %ScanButton

@onready var tree: DraggableTree = %DraggableTree

@onready var instance_button: Button = %InstanceButton
@onready var edit_button: Button = %EditButton
@onready var duplicate_button: Button = %DuplicateButton
@onready var remove_button: Button = %RemoveButton


func _ready() -> void:
	var new_popup := new_button.get_popup()
	new_popup.get_window().transparent = true
	new_popup.id_pressed.connect(_on_new_popup_id_pressed)
	folder_button.pressed.connect(_on_folder_button_pressed)
	scan_button.pressed.connect(_on_scan_button_pressed)
	
	instance_button.pressed.connect(_on_instance_button_pressed)
	edit_button.pressed.connect(_on_edit_button_pressed)
	duplicate_button.pressed.connect(_on_duplicate_button_pressed)
	remove_button.pressed.connect(_on_remove_button_pressed)
	
	visibility_changed.connect(_on_visibility_changed)
	
	#tree.item_selected.connect(_on_item_selected)
	tree.multi_selected.connect(_on_multi_selected)
	tree.item_mouse_selected.connect(_on_item_mouse_selected)
	tree.item_activated.connect(_on_item_activated)
	tree.item_collapsed.connect(_on_item_collapsed)
	tree.item_edited.connect(_on_item_edited)
	tree.items_dropped.connect(_on_items_dropped)
	
	tree.drag_type = "campaign_blueprint_items"
	tree.drop_types_allowed = [
		"campaign_blueprint_items"
	]
	

func _on_new_popup_id_pressed(id: int) -> void:
	var blueprint: CampaignBlueprint
	match id:
		0: blueprint = save_new(CampaignBlueprint.Type.FOLDER, "New Folder")
		1: blueprint = save_new(CampaignBlueprint.Type.LIGHT, "New Light")
		2: blueprint = save_new(CampaignBlueprint.Type.ENTITY, "New Entity")
		3: blueprint = save_new(CampaignBlueprint.Type.PROP, "New Prop")
	
	item_selected.collapsed = false
	items_collapsed[blueprint.id] = false
	_on_instance_button_pressed()


func _on_folder_button_pressed() -> void:
	Utils.open_in_file_manager(blueprint_selected.abspath)


func _on_scan_button_pressed() -> void:
	reset()
	Utils.temp_info_tooltip("Blueprints reloaded")
	

func _on_visibility_changed():
	pass


#func _on_item_selected():
	#current_item_selected = item_selected
	#current_item_path = Utils.get_tree_path(current_item_selected)
	#current_item_id = blueprint_selected.id


func _on_multi_selected(item: TreeItem, _column: int, selected: bool):
	var blueprint := get_item_blueprint(item)
	items_selected[blueprint.id] = selected


func _on_item_mouse_selected(_mouse_position: Vector2, mouse_button_index: int):
	if item_selected == root: 
		return
		
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		DisplayServer.clipboard_set(blueprint_selected.path)
		Utils.temp_info_tooltip("Copied!", 1)


func _on_item_collapsed(item: TreeItem):
	var blueprint := get_item_blueprint(item)
	items_collapsed[blueprint.id] = item.collapsed
	
	
func _on_item_edited():
	var item := tree.get_edited()
	var new_name := item.get_text(0)
	if not new_name:
		item.set_text(0, current_item_path.get_file())
		return
		
	var abspath := Game.campaign.get_blueprint_abspath(current_item_path)
	var new_path = Utils.get_tree_path(item)
	var new_abspath := Game.campaign.get_blueprint_abspath(new_path)
	
	if abspath == new_abspath:
		return
		
	var siblings := Utils.dir_siblings_count(new_abspath, " ")
	if siblings > 0:
		new_path = "%s %s" % [new_path, siblings + 1]
		new_abspath = "%s %s" % [new_abspath, siblings + 1]
			
		item.set_text(0, new_abspath.get_file())
		
	if Utils.rename(abspath, new_abspath):
		Utils.temp_error_tooltip("\"%s\" In use by another app" % abspath)
		return
		
	Debug.print_info_message("Renamed blueprint from \"%s\" to \"%s\"" % [current_item_path, new_path])
	
	current_item_path = new_path
	sort_children(item.get_parent())
	tree.deselect_all()
	items_selected.clear()
	item.select(0)
	items_selected[blueprint_selected.id] = true


func _on_item_activated():
	if item_selected == root:
		item_selected.collapsed = not item_selected.collapsed
		return
	
	_on_instance_button_pressed()


func _on_items_dropped(_type: String, items: Array, item_at_position: TreeItem, drop_section: int):
	var item_abspaths := items.map(_get_item_abspath)
	
	# tree move
	for i in items.size():
		var item: TreeItem = items[i]
		if drop_section == -1:
			item.move_before(item_at_position)
		elif drop_section == 1:
			item.move_after(item_at_position if i == 0 else items[i - 1])
		else:
			item.get_parent().remove_child(item)
			item_at_position.add_child(item)
	
	# physical move
	var item_new_abspaths := items.map(_get_item_abspath)
	var item_path_errors := []
	for i in items.size():
		var item: TreeItem = items[i]
		var abspath: String = item_abspaths[i]
		var new_abspath: String = item_new_abspaths[i]
		if abspath == new_abspath:
			continue
			
		if not DirAccess.dir_exists_absolute(abspath):  # parent was moved
			continue
			
		var siblings := Utils.dir_siblings_count(new_abspath, " ")
		if siblings > 0:
			new_abspath = "%s %s" % [new_abspath, siblings + 1]
			item.set_text(0, new_abspath.get_file())
			
		if Utils.rename(abspath, new_abspath):
			item_path_errors.append("\"%s\" In use by another app" % abspath)
	
	# recreate tree if errors
	if item_path_errors:
		reset()
		if item_path_errors.size() == 1:
			Utils.temp_error_tooltip(item_path_errors[0])
		else:
			Utils.temp_error_tooltip(Utils.unsorted_list_string(item_path_errors))
		return
			
	var item_parent := item_at_position if drop_section == 0 else item_at_position.get_parent()
	if not item_parent:
		item_parent = root
	item_parent.collapsed = false
	sort_children(item_parent)

	_regenerate_selection()


func _get_item_abspath(item: TreeItem) -> String:
	return Game.campaign.get_blueprint_abspath(Utils.get_tree_path(item))


func reset() -> void:
	if not Game.campaign or not Game.campaign.is_master:
		return
		
	blueprint_items.clear()
	tree.clear()
	root = tree.create_item()
	root.set_icon(0, DIRECTORY_ICON)
	root.set_text(0, "Blueprints")
	root.set_tooltip_text(0, " ")
	var root_blueprint = CampaignBlueprint.new(CampaignBlueprint.Type.FOLDER, "")
	root.set_metadata(0, root_blueprint)
	blueprint_items[""] = root
	Game.blueprints[""] = root_blueprint
	
	walk_dirs(root, Game.campaign.blueprints_path)
	sort_children(root)
	_regenerate_selection()
	
	# customize item line_edit
	for child in tree.get_children(true):
		if is_instance_of(child, Popup):
			child.transparent = true
			for child_child in child.get_children(true):
				if is_instance_of(child_child, VBoxContainer):
					for child_child_child in child_child.get_children(true):
						if is_instance_of(child_child_child, LineEdit):
							child_child_child.caret_blink = true


func _regenerate_selection():
	tree.deselect_all()
	var has_selections := false
	for blueprint_id in items_selected:
		var selected: bool = items_selected[blueprint_id]
		if selected:
			var item: TreeItem = blueprint_items.get(blueprint_id)
			if item:
				item.select(0)
				has_selections = true
	if not has_selections:
		root.select(0)


func add_blueprint(parent: TreeItem, blueprint_name: String, blueprint: CampaignBlueprint) -> TreeItem:
	var blueprint_item := parent.create_child()
	
	blueprint_item.set_text(0, blueprint_name)
	blueprint_item.set_tooltip_text(0, " ")
	blueprint_item.set_metadata(0, blueprint)
	match blueprint.type:
		CampaignBlueprint.Type.FOLDER: blueprint_item.set_icon(0, DIRECTORY_ICON)
		_: blueprint_item.set_icon(0, GODOT_ICON)
	
	var color: Color = blueprint.properties.get("color", Color.WHITE)
	blueprint_item.set_icon_modulate(0, Color.WHITE if color.get_luminance() < 0.1 else color)
	
	blueprint_items[blueprint.id] = blueprint_item
	Game.blueprints[blueprint.id] = blueprint
	
	return blueprint_item


func set_item_color(id: String, color: Color):
	var blueprint_item: TreeItem = blueprint_items.get(id)
	if not blueprint_item:
		return
	blueprint_item.set_icon_modulate(0, Color.WHITE if color.get_luminance() < 0.1 else color)


func walk_dirs(parent: TreeItem, path: String):
	var relative_path: String = path.substr(len(Game.campaign.blueprints_path) + 1)
	for blueprint_name in DirAccess.get_directories_at(path):
		var blueprint_path := relative_path.path_join(blueprint_name)
		var blueprint_data := Game.campaign.get_blueprint_data(blueprint_path)
		var blueprint_type: String = blueprint_data.get("type", CampaignBlueprint.Type.FOLDER)
		var blueprint_id: String = blueprint_data.get("id", Utils.random_string(8, true))
		var blueprint_raw_properties: Dictionary = blueprint_data.get("properties", {})
		var blueprint: CampaignBlueprint = Game.blueprints.get(blueprint_id)
		if blueprint:
			blueprint.type = blueprint_type
			blueprint.set_raw_properties(blueprint_raw_properties)
		else:
			blueprint = CampaignBlueprint.new(blueprint_type, blueprint_id, blueprint_raw_properties)
			
		var blueprint_item := add_blueprint(parent, blueprint_name, blueprint)
		blueprint_item.collapsed = items_collapsed.get(blueprint_id, true)
		
		walk_dirs(blueprint_item, path.path_join(blueprint_name))


func _on_instance_button_pressed():
	if item_selected == root:
		Utils.temp_error_tooltip("Cannot instance root")
		return
	var blueprint := blueprint_selected
	if not blueprint:
		Utils.temp_error_tooltip("Select a Blueprint")
		return
	
	match blueprint.type:
		CampaignBlueprint.Type.FOLDER:
			item_selected.collapsed = not item_selected.collapsed
	
		CampaignBlueprint.Type.ENTITY:
			Game.modes.change_mode(ModeController.Mode.ENTITY_3D_SHAPE)
			level.state_machine.get_state_node(Level.State.GO_ELEMENT_INSTANCING).preview_blueprint = blueprint
	
		CampaignBlueprint.Type.LIGHT:
			Game.modes.change_mode(ModeController.Mode.LIGHT_OMNILIGHT)
			level.state_machine.get_state_node(Level.State.GO_ELEMENT_INSTANCING).preview_blueprint = blueprint
	
		CampaignBlueprint.Type.PROP:
			Game.modes.change_mode(ModeController.Mode.PROP_3D_SHAPE)
			level.state_machine.get_state_node(Level.State.GO_ELEMENT_INSTANCING).preview_blueprint = blueprint


func _on_edit_button_pressed():
	if item_selected == root:
		Utils.temp_error_tooltip("Cannot rename root")
		return
	tree.edit_selected(true)
	current_item_path = blueprint_selected.path
	current_item_id = blueprint_selected.id
	

func _on_duplicate_button_pressed():
	if item_selected == root:
		Utils.temp_error_tooltip("Cannot duplicate root")
		return
	
	save_new(blueprint_selected.type, blueprint_selected.name, 
			blueprint_selected.get_raw_properties(), item_selected.get_parent())


func _on_remove_button_pressed():
	var selected_items: Array[TreeItem] = []
	var next_selected := tree.get_next_selected(null)
	var item_to_be_selected := next_selected.get_prev_in_tree()
	while next_selected:
		selected_items.append(next_selected)
		next_selected = tree.get_next_selected(next_selected)
	
	if root in selected_items:
		Utils.temp_error_tooltip("Cannot remove root")
		return
		
	selected_items.reverse()
	for item in selected_items:
		var blueprint := get_item_blueprint(item)
		blueprint.remove()
		item.free()
		
	tree.deselect_all()
	item_to_be_selected.select(0)
	items_selected.clear()
	items_selected[get_item_blueprint(item_to_be_selected).id] = true


func save_new(type: String, blueprint_name: String, 
		raw_properties := {}, parent: TreeItem = null) -> CampaignBlueprint:
	var item := item_selected
	if not item:
		item = root
	if not parent:
		parent = item
	
	var blueprint_basedir: String = Utils.get_tree_path(parent)
	var blueprint_path := blueprint_basedir.path_join(blueprint_name)
	var blueprint_abspath := Game.campaign.get_blueprint_abspath(blueprint_path)
	var siblings := Utils.dir_siblings_count(blueprint_abspath, " ")
	if siblings > 0:
		blueprint_path = "%s %s" % [blueprint_path, siblings + 1]
	var blueprint_data := {
		"type": type, 
		"id": Utils.random_string(8, true), 
		"properties": raw_properties,
	}
	Game.campaign.set_blueprint_data(blueprint_path, blueprint_data)
	
	var blueprint: = CampaignBlueprint.new(type, blueprint_data.id, raw_properties)
	var blueprint_item := add_blueprint(parent, blueprint_path.get_file(), blueprint)
	var parent_item := blueprint_item.get_parent()
	var parent_blueprint := get_item_blueprint(parent_item)
	items_collapsed[parent_blueprint.id] = false
	sort_children(parent_item)
	tree.deselect_all()
	items_selected.clear()
	blueprint_item.uncollapse_tree()
	blueprint_item.select(0)
	items_selected[blueprint.id] = true
	
	return blueprint


func sort_children(item: TreeItem):
	for child in item.get_children():
		sort_children(child)
		
	var sorted_children := item.get_children()
	sorted_children.sort_custom(func(a: TreeItem, b: TreeItem) -> int:
		var blueprint_a = get_item_blueprint(a)
		var blueprint_b = get_item_blueprint(b)
		if blueprint_a.is_folder and not blueprint_b.is_folder:
			return true
		if not blueprint_a.is_folder and blueprint_b.is_folder:
			return false
		return a.get_text(0).naturalnocasecmp_to(b.get_text(0)) == -1
	)
	for child in item.get_children():
		item.remove_child(child)
	for child in sorted_children:
		item.add_child(child)
	

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_F2:
			edit_button.pressed.emit()
