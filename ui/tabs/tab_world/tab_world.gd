class_name TabWorld
extends Control


const TAB_SCENE := preload("res://ui/tabs/tab_scene/tab_scene.tscn")
const PLAY_ICON := preload("res://resources/icons/play_icon.png")
const PLAY_SCENE_ICON := preload("res://resources/icons/play_scene_icon.png")
const SCENE_ICON = preload("res://resources/icons/scene_icon.png")

var campaign_selected: Campaign : 
	set(value):
		campaign_selected = value
		scan(value)
		refresh_tree()
		

var selected_map_slug: String :
	get: return tree.get_selected().get_tooltip_text(0) if tree.get_selected() else ""


var cached_maps := {}  # {map_slug: map_data}
var players_map := ""


@onready var new_button: Button = %NewButton
@onready var folders_button: Button = %FoldersButton
@onready var scan_button: Button = %ScanButton
@onready var filter_line_edit: LineEdit = %TitleLineEdit
@onready var tree: Tree = %Tree
@onready var open_button: Button = %OpenButton
@onready var players_button: Button = %PlayersButton
@onready var close_button: Button = %CloseButton
@onready var remove_button: Button = %RemoveButton


var root: TreeItem

func _set_opened(map_item: TreeItem, value: bool):
	if value:
		map_item.set_icon(0, SCENE_ICON)
	else:
		map_item.set_icon(0, null)


func _ready() -> void:
	new_button.pressed.connect(_on_new_button_pressed)
	folders_button.pressed.connect(_on_folders_button_pressed)
	scan_button.pressed.connect(reset)
	
	filter_line_edit.text_changed.connect(refresh_tree.unbind(1))
	tree.hide_root = true
	tree.item_activated.connect(open_selected_map)
	tree.button_clicked.connect(_on_button_clicked)
	
	open_button.pressed.connect(open_selected_map)
	players_button.pressed.connect(_on_players_button_pressed)
	close_button.pressed.connect(_on_close_selected_map_pressed)
	remove_button.pressed.connect(_on_remove_button_pressed)


func _on_new_button_pressed():
	var campaign_path := campaign_selected.path
	var map_path := campaign_path.path_join("maps/untitled-map")
	var siblings := Utils.create_unique_folder(map_path)
	var map_unique_path := map_path if siblings == 1 else "%s-%s" % [map_path, siblings]
	Utils.dump_json(map_unique_path.path_join("map.json"), {
		"label": "Untitled Map" if siblings == 1 else "Untitled Map %s" % siblings
	})
	
	reset()


func scan(campaign: Campaign):
	cached_maps.clear()
	if not campaign:
		return
	
	for map_slug in Utils.sort_strings_ended_with_number(campaign.maps):
		cached_maps[map_slug] = campaign.get_map_data(map_slug)


func refresh_tree():
	var filter := filter_line_edit.text
	var cached_slug := selected_map_slug
	
	tree.clear()
	root = tree.create_item()
	tree.set_column_title(0, "Maps")
	
	for map_slug in cached_maps:
		var map_data: Dictionary = cached_maps[map_slug]
		if filter and filter.to_lower() not in map_data.label.to_lower():
			continue
			
		var map_item = tree.create_item(root)
	
		map_item.set_text(0, map_data.label)
		map_item.set_tooltip_text(0, map_slug)
		map_item.set_metadata(0, map_data)
		map_item.add_button(0, PLAY_ICON, 0)
		map_item.set_button_tooltip_text(0, 0, "Send players to map")
		
		if map_slug in Game.maps:
			_set_opened(map_item, true)
	
		if cached_slug == map_slug:
			map_item.select(0)
		
		if players_map == map_slug:
			map_item.set_button_color(0, 0, Color.GREEN)
		else:
			map_item.set_button_color(0, 0, Color.DARK_GRAY)
			
		if Game.ui.selected_map and Game.ui.selected_map.slug == map_slug:
			map_item.set_icon_modulate(0, Color.GREEN)
		else:
			map_item.set_icon_modulate(0, Color.WHITE)


func open_selected_map():
	var map_item := tree.get_selected()
	if not map_item:
		Utils.temp_error_tooltip("Select a map to be open")
		return
		
	var map_slug: String = selected_map_slug
	if map_slug == Game.ui.selected_map.slug:
		Utils.temp_warning_tooltip("Select a map is already open")
		return
		
	if map_slug in Game.maps:
		var tab_index = Game.maps.keys().find(map_slug)
		Game.ui.scene_tabs.current_tab = tab_index
		return

	_set_opened(map_item, true)
	var new_tab_index := Game.ui.scene_tabs.get_tab_count()
	var tab_scene: TabScene = TAB_SCENE.instantiate().init(map_slug, cached_maps[map_slug])
	Game.ui.scene_tabs.current_tab = new_tab_index
	
	var camera_init_position := Utils.v2i_to_v3(tab_scene.map.selected_level.rect.get_center()) + Vector3.UP * 0.5
	tab_scene.map.camera.target_position.position = camera_init_position


func _on_players_button_pressed():
	var map_slug: String = selected_map_slug
	
	if map_slug == players_map:
		Utils.temp_warning_tooltip("Players already are in this map")
		return
	
	open_selected_map()
	
	send_players_to_map(map_slug)
	
	refresh_tree()


func _on_button_clicked(item: TreeItem, column: int, _id: int, _mouse_button_index: int) -> void:
	item.select(column)
	_on_players_button_pressed()


func send_players_to_map(map_slug):
	players_map = map_slug
	
	Game.server.request_map_notification.rpc(players_map)
	
	for map_item in root.get_children():
		var map_item_slug := map_item.get_tooltip_text(0)
		var tab_index = Game.maps.keys().find(map_item_slug)
		
		if map_item_slug == players_map:
			Game.ui.scene_tabs.set_tab_icon(tab_index, PLAY_SCENE_ICON)
			map_item.set_button_color(0, 0, Color.GREEN)
		else:
			if tab_index != -1:
				Game.ui.scene_tabs.set_tab_icon(tab_index, SCENE_ICON)
				Game.ui.scene_tabs.get_tab_control(tab_index).process_mode = Node.PROCESS_MODE_DISABLED
			map_item.set_button_color(0, 0, Color.DARK_GRAY)


func _on_folders_button_pressed() -> void:
	var path := campaign_selected.maps_path
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(path))
	

func _close_selected_map():
	for tab_index in range(Game.ui.scene_tabs.get_tab_count()):
		var tab_scene: TabScene = Game.ui.scene_tabs.get_tab_control(tab_index)
		var map := tab_scene.map
			
		if map.slug == selected_map_slug:
			tab_scene.queue_free()
			break


func _on_close_selected_map_pressed():
	var map_item := tree.get_selected()
	if not map_item:
		Utils.temp_error_tooltip("Select a map to be closed")
		return
	
	if selected_map_slug not in Game.maps:
		Utils.temp_error_tooltip("Selected map is not open")
		return
	
	if selected_map_slug == players_map:
		Utils.temp_error_tooltip("Send player them to another map")
		return
		
	_close_selected_map()
	Game.maps.erase(selected_map_slug)
	reset()


func _on_remove_button_pressed():
	var map_item := tree.get_selected()
	if not map_item:
		Utils.temp_error_tooltip("Select a map to be removed")
		return
	
	if selected_map_slug == players_map:
		Utils.temp_error_tooltip("Send player them to another map")
		return
		
	_close_selected_map()
	Game.maps.erase(selected_map_slug)
	Utils.move_to_trash(campaign_selected.get_map_path(selected_map_slug))
	reset()


func reset():
	scan(campaign_selected)
	refresh_tree()
