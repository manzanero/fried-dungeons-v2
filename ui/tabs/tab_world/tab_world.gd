class_name TabWorld
extends Control


const TAB_SCENE := preload("res://ui/tabs/tab_scene/tab_scene.tscn")
const PLAY_ICON := preload("res://resources/icons/play_icon.png")


var campaign_selected: Campaign : 
	set(value):
		campaign_selected = value
		scan(value)
		refresh_tree()
		

var selected_map_slug: String :
	get: 
		return tree.get_selected().get_tooltip_text(0)


var cached_maps := {}
var players_map := ""


@onready var new_button: Button = %NewButton
@onready var scan_button: Button = %ScanButton
@onready var filter_line_edit: LineEdit = %TitleLineEdit
@onready var tree: Tree = %Tree
@onready var open_button: Button = %OpenButton
@onready var folder_button: Button = %FolderButton
@onready var remove_button: Button = %RemoveButton


var root: TreeItem

func _set_opened(map_item: TreeItem, value: bool):
	if value:
		map_item.set_icon(0, preload("res://resources/icons/arrow_right.png"))
	else:
		map_item.set_icon(0, null)


func _ready() -> void:
	new_button.pressed.connect(_on_new_button_pressed)
	scan_button.pressed.connect(_on_scan_button_pressed)
	filter_line_edit.text_changed.connect(_on_filter_text_changed)
	open_button.pressed.connect(_on_open_button_pressed)
	folder_button.pressed.connect(_on_folder_button_pressed)
	remove_button.pressed.connect(_on_remove_button_pressed)
	tree.hide_root = true
	tree.item_activated.connect(_on_open_button_pressed)
	tree.button_clicked.connect(_on_button_clicked)


func _on_new_button_pressed():
	var campaign_path := campaign_selected.campaign_path
	var map_path := campaign_path.path_join("maps/untitled-map")
	var siblings := Utils.create_unique_folder(map_path)
	var map_unique_path := map_path if siblings == 1 else "%s-%s" % [map_path, siblings]
	Utils.dump_json(map_unique_path.path_join("map.json"), {
		"label": "Untitled Map" if siblings == 1 else "Untitled Map %s" % siblings
	})
	
	scan(campaign_selected) 
	refresh_tree()


func _on_scan_button_pressed():
	scan(campaign_selected)
	refresh_tree()


func _on_filter_text_changed(_new_text: String):
	refresh_tree()


func scan(campaign: Campaign):
	cached_maps.clear()
	if not campaign:
		return
	
	for map_slug in Utils.sort_strings_ended_with_number(campaign.maps):
		cached_maps[map_slug] = campaign.get_map_data(map_slug)


func refresh_tree():
	var filter := filter_line_edit.text
	
	tree.clear()
	root = tree.create_item()
	
	for map_slug in cached_maps:
		var map_data: Dictionary = cached_maps[map_slug]
		if filter and filter.to_lower() not in map_data.label.to_lower():
			continue
			
		var map_item = tree.create_item(root)
		
		if map_slug in Game.maps:
			_set_opened(map_item, true)
	
		map_item.set_text(0, map_data.label)
		map_item.set_tooltip_text(0, map_slug)
		map_item.set_metadata(0, map_data)
	
		map_item.add_button(0, PLAY_ICON, 0)
		map_item.set_button_color(0, 0, Color.DARK_GRAY)


func _on_open_button_pressed():
	var map_item := tree.get_selected()
	if not map_item:
		return
		
	if selected_map_slug in Game.maps:
		var tab_index = Game.maps.keys().find(selected_map_slug)
		Game.ui.scene_tabs.current_tab = tab_index
		return

	_set_opened(map_item, true)
	var new_tab_index := Game.ui.scene_tabs.get_tab_count()
	var tab_scene: TabScene = TAB_SCENE.instantiate().init(selected_map_slug, cached_maps[selected_map_slug])
	Game.ui.scene_tabs.current_tab = new_tab_index
	
	
	tab_scene.map.camera.target_position.position = Utils.v2i_to_v3(tab_scene.map.selected_level.rect.get_center())


func _on_button_clicked(item: TreeItem, column: int, _id: int, _mouse_button_index: int) -> void:
	item.select(column)
	if selected_map_slug == players_map:
		return
		
	_on_open_button_pressed()
	for child_item in root.get_children(): 
		child_item.set_button_color(0, 0, Color.DARK_GRAY)
	
	item.set_button_color(0, 0, Color.GREEN)
	Game.server.request_map_notification.rpc(selected_map_slug)


func _on_folder_button_pressed() -> void:
	var map_item := tree.get_selected()
	if not map_item:
		return
	
	var path := campaign_selected.maps_path.path_join(selected_map_slug)
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(path))
	

func _on_remove_button_pressed():
	var map_item := tree.get_selected()
	if not map_item:
		return
		
	var path := campaign_selected.maps_path.path_join(selected_map_slug)
	Utils.remove_dirs(path)
	if selected_map_slug in Game.ui.opened_maps.keys():
		Game.ui.scene_tabs.get_tab_control(Game.ui.opened_maps.keys().find(selected_map_slug)).queue_free()
	
	scan(campaign_selected)
	refresh_tree()
