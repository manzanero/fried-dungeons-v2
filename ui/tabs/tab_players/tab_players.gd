class_name TabPlayers
extends Control

const PLAY_ICON := preload("res://resources/icons/play_icon.png")
const PAUSE_ICON := preload("res://resources/icons/pause_icon.png")
const STOP_ICON := preload("res://resources/icons/stop_icon.png")
const RESET_ICON := preload("res://resources/icons/reload_icon.png")
const PLAYER_ICON = preload("res://resources/icons/round_icon.png")
const MOVEMENT_ICON = preload("res://resources/icons/movement_icon.png")
const VISIBILITY_VISIBLE_ICON = preload("res://resources/icons/visibility_visible_icon.png")
const CROSS_ICON = preload("res://resources/icons/cross_icon.png")
const SQUARE_ICON = preload("res://resources/icons/square_icon.png")

@onready var new_button: Button = %NewButton
@onready var scan_button: Button = %ScanButton
@onready var name_line_edit: LineEdit = %NameLineEdit

@onready var players_tree: DraggableTree = %PlayersTree
@onready var persmissions_tree: DraggableTree = %PermissionsTree

@onready var add_entity_button: Button = %AddEntityButton
@onready var open_vision_button: Button = %OpenVisionButton
@onready var center_view_button: Button = %CenterViewButton


var player_items: Dictionary :  # slug: TreeItem
	get: 
		var _player_items := {}
		var _players_root := players_tree.get_root()
		if _players_root:
			for player_item in _players_root.get_children():
				_player_items[player_item.get_tooltip_text(0)] = player_item
		return _player_items

var player_selected_item: TreeItem :
	get: return players_tree.get_selected() 
	
var current_player_slug: String

var player_selected_slug: String :
	get: return player_selected_item.get_tooltip_text(0) if player_selected_item else Game.NULL_STRING

var player_selected_item_data: Dictionary :
	get: return player_selected_item.get_metadata(0) if player_selected_item else {}


func get_player_slug(player_item: TreeItem) -> String:
	return player_item.get_tooltip_text(0)

func get_player_item(player_slug: String) -> TreeItem:
	return player_items.get(player_slug)

func get_player_item_data(player_slug: String) -> Dictionary:
	var player_item := get_player_item(player_slug)
	return player_item.get_metadata(0) if player_item else {}

func get_element_id(element_item: TreeItem) -> String:
	return element_item.get_tooltip_text(0)


func _ready() -> void:
	Game.manager.campaign_loaded.connect(reset)
	Game.flow.changed.connect(func (): 
		var root := players_tree.get_root()
		if root:
			_set_flow(root, Game.flow.state)
	)
	
	new_button.pressed.connect(_on_new_button_pressed)
	#folders_button.pressed.connect(_on_folders_button_pressed)
	scan_button.pressed.connect(_on_scan_button_pressed)
	name_line_edit.text_changed.connect(_on_filter_text_changed)
	
	players_tree.button_clicked.connect(_on_player_item_button_clicked)
	players_tree.item_selected.connect(_on_player_item_selected)
	players_tree.item_activated.connect(_on_open_vision_button_pressed)
	
	persmissions_tree.button_clicked.connect(_on_persmission_item_button_clicked)
	
	add_entity_button.pressed.connect(_on_add_entity_button_pressed)
	open_vision_button.pressed.connect(_on_open_vision_button_pressed)
	center_view_button.pressed.connect(_on_center_view_button_pressed)
	

func _on_new_button_pressed():
	Game.ui.nav_bar.campaign_players_pressed.emit()

#func _on_folders_button_pressed() -> void:
	#OS.shell_show_in_file_manager(ProjectSettings.globalize_path(Game.campaign.players_path))

func _on_filter_text_changed():
	var filter := Utils.slugify(name_line_edit.text.to_lower())
	for item in player_items:
		var data: Dictionary = item.get_metadata(0)
		if filter and filter not in Utils.slugify(data.username.to_lower()):
			item.visible = false
		else:
			item.visible = true


func _on_scan_button_pressed():
	reset()


func reset():
	if not Game.player_is_master:
		return
	
	players_tree.clear()
	var players_root := players_tree.create_item()
	players_root.set_text(0, Game.master.username)
	players_root.set_icon(0, SQUARE_ICON)
	players_root.set_icon_modulate(0, Game.master.color)
	players_root.set_tooltip_text(0, " ")
	players_root.set_metadata(0, {})
	
	players_root.add_button(0, RESET_ICON, 0)
	players_root.add_button(0, PLAY_ICON, 1)
	players_root.add_button(0, PAUSE_ICON, 2)
	players_root.add_button(0, STOP_ICON, 3)
	players_root.set_button_color(0, 0, Game.TREE_BUTTON_OFF_COLOR)
	players_root.set_button_color(0, 1, Game.TREE_BUTTON_OFF_COLOR)
	players_root.set_button_color(0, 2, Game.TREE_BUTTON_OFF_COLOR)
	players_root.set_button_color(0, 3, Game.TREE_BUTTON_OFF_COLOR)
	
	persmissions_tree.clear()
	persmissions_tree.create_item()
	
	var campaign_data: Dictionary = Game.campaign.load_campaign_data()
	var campaign_players: Dictionary = campaign_data.get("players", {})
	
	_set_flow(players_root, Game.flow.state)
	
	var player_slugs := DirAccess.get_directories_at(Game.campaign.players_path)
	for player_slug in player_slugs:
		var player_data := Game.campaign.get_player_data(player_slug)
		if Game.server.is_steam_game and not player_data.get("steam_user"):
			continue
		
		var player_username: String = player_data.username
		var player_item_data: Dictionary = campaign_players.get(player_slug, {})
		var player_state: FlowController.State = player_item_data.get_or_add("state", FlowController.State.NONE)
		
		var player_item := players_root.create_child()
		player_item.set_text(0, player_username)
		player_item.set_icon(0, SQUARE_ICON)
		player_item.set_icon_modulate(0, Utils.html_color_to_color(player_data.get_or_add("color", "ffffff")))
		
		#player_item.set_custom_color(0, Color.BROWN)
		player_item.set_tooltip_text(0, player_slug)
		player_item.set_metadata(0, player_item_data)
		
		player_item.add_button(0, RESET_ICON, 0)
		player_item.set_button_color(0, 0, Game.TREE_BUTTON_OFF_COLOR)
		player_item.add_button(0, PLAY_ICON, 1)
		player_item.add_button(0, PAUSE_ICON, 2)
		player_item.add_button(0, STOP_ICON, 3)
		_set_flow(player_item, player_state)
	
func _on_player_item_selected():
	persmissions_tree.clear()
	persmissions_tree.create_item()
	var player_item := players_tree.get_selected()
	if player_item == players_tree.get_root():
		Game.player = null
		return
		
	var player_slug := player_item.get_tooltip_text(0)
	current_player_slug = player_slug
	var player_data := Game.campaign.get_player_data(player_slug)
	var player_elements: Dictionary = player_data.get("elements", {})
	for element_id in player_elements:
		var element_control_data := {
			"movement": player_elements[element_id].get("movement", false),
			"senses": player_elements[element_id].get("senses", false),
		}
		create_child_element(element_id, element_control_data)
		
	Utils.sort_item_children(persmissions_tree.get_root())
	
	Game.player = Player.new(player_slug, player_data)


func create_child_element(element_id: String, element_control_data: Dictionary):
	var element_item := persmissions_tree.get_root().create_child()
	element_item.set_text(0, element_id)
	element_item.set_tooltip_text(0, element_id)
	#element_item.set_metadata(0, element_item_data)
	
	# set buttons
	element_item.add_button(0, MOVEMENT_ICON, 0)
	element_item.set_button_color(0, 0, Game.TREE_BUTTON_OFF_COLOR)
	if element_control_data.movement: 
		element_item.set_button_color(0, 0, Color.WHITE)
	element_item.add_button(0, VISIBILITY_VISIBLE_ICON, 1)
	element_item.set_button_color(0, 1, Game.TREE_BUTTON_OFF_COLOR)
	if element_control_data.senses: 
		element_item.set_button_color(0, 1, Color.WHITE)
	element_item.add_button(0, CROSS_ICON, 2)
	element_item.set_button_color(0, 2, Game.TREE_BUTTON_OFF_COLOR)


func _on_player_item_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int):
	
	# all item
	var is_all_item := item == players_tree.get_root()
	if is_all_item:
		match id:
			0: reset_all_players()
			1: _set_flow(item, FlowController.State.PLAYING); Game.flow.play()
			2: _set_flow(item, FlowController.State.PAUSED); Game.flow.pause()
			3: _set_flow(item, FlowController.State.STOPPED); Game.flow.stop()
			
		Game.server.rpcs.change_flow_state.rpc(Game.flow.state, get_data())
		return
	
	# player item
	var player_item_data: Dictionary = item.get_metadata(0)
	player_item_data.state = id
	item.set_metadata(0, player_item_data)
	match id:
		0: _set_flow(item, FlowController.State.NONE)
		1: _set_flow(item, FlowController.State.PLAYING)
		2: _set_flow(item, FlowController.State.PAUSED)
		3: _set_flow(item, FlowController.State.STOPPED)
	
	Game.server.rpcs.change_flow_state.rpc(Game.flow.state, get_data())
	return


func _on_persmission_item_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int):
	match id:
		0: _toggle_permission(current_player_slug, item, Player.Permission.MOVEMENT)
		1: _toggle_permission(current_player_slug, item, Player.Permission.SENSES)
		2: _clear_permisions(current_player_slug, item)
		

func reset_all_players():
	_set_flow(players_tree.get_root(), Game.flow.state)
	for player_slug in player_items:
		_set_flow(player_items[player_slug], FlowController.State.NONE)


func _reset_item_flow(item):
	item.set_button_color(0, 1, Game.TREE_BUTTON_OFF_COLOR)
	item.set_button_color(0, 2, Game.TREE_BUTTON_OFF_COLOR)
	item.set_button_color(0, 3, Game.TREE_BUTTON_OFF_COLOR)


func _set_flow(item: TreeItem, state: FlowController.State):
	_reset_item_flow(item)
	
	var player_item_data: Dictionary = item.get_metadata(0)
	if player_item_data:
		player_item_data.state = state
		item.set_metadata(0, player_item_data)
	match state:
		FlowController.State.PLAYING: 
			item.set_button_color(0, 1, Color.GREEN)
		FlowController.State.PAUSED: 
			item.set_button_color(0, 2, Color.YELLOW)
		FlowController.State.STOPPED: 
			item.set_button_color(0, 3, Color.RED)


func _toggle_permission(player_slug: String, item: TreeItem, permission: String):
	var element_label := get_element_id(item)
	var player_data := Game.campaign.get_player_data(player_slug)
	var player_elements: Dictionary = player_data.get_or_add("elements", {})
	var control_data: Dictionary = player_elements.get_or_add(element_label, {})
	
	match permission:
		Player.Permission.MOVEMENT: 
			var allow_movement: bool = not control_data.get_or_add("movement", false)
			control_data[permission] = allow_movement
			item.set_button_color(0, 0, Color.WHITE if allow_movement else Game.TREE_BUTTON_OFF_COLOR)
		Player.Permission.SENSES: 
			var allow_senses: bool = not control_data.get_or_add("senses", false)
			control_data[permission] = allow_senses
			item.set_button_color(0, 1, Color.WHITE if allow_senses else Game.TREE_BUTTON_OFF_COLOR)
	
	Game.campaign.set_player_data(player_slug, player_data)
	
	Game.server.rpcs.set_player_element_control.rpc(player_slug, element_label, control_data)
	
	if Game.master_is_player:
		Game.player.set_element_control(element_label, control_data)
		Game.ui.selected_map.selected_level.set_control(player_data.elements)
	
	Debug.print_info_message("Entity \"%s\" %s added to player \"%s\"" % \
			[element_label, permission, player_slug])


func _clear_permisions(player_slug: String, item: TreeItem):
	var element_label := get_element_id(item)
	var player_data := Game.campaign.get_player_data(player_slug)
	player_data.elements.erase(element_label)
	
	item.free()
	
	Game.campaign.set_player_data(player_slug, player_data)
	
	Game.server.rpcs.set_player_element_control.rpc(player_slug, element_label)
	
	if Game.master_is_player:
		Game.player.clear_element_control(element_label)
		Game.ui.selected_map.selected_level.set_control(player_data.elements)
	
	Debug.print_info_message("Entity \"%s\" removed to player \"%s\"" % \
			[element_label, player_slug])
	
	
func _on_add_entity_button_pressed():
	var element_selected := Game.ui.selected_map.selected_level.element_selected; 
	if not is_instance_valid(element_selected) or element_selected is not Entity:
		Utils.temp_error_tooltip("Select an Entity to asign")
		return
	
	if not player_selected_item:
		Utils.temp_error_tooltip("Select the player to be asignted")
		return
	
	if players_tree.get_selected() == players_tree.get_root():
		pass
		#for player_slug in player_items:
			#add_entity(player_slug, element_selected, true)
	else:
		add_entity(player_selected_slug, element_selected)
	

func add_entity(player_slug: String, element_selected: Element, assigned_ok := false):
	var player_data := Game.campaign.get_player_data(player_slug)
	var player_elements: Dictionary = player_data.get_or_add("elements", {})
	if element_selected.label in player_elements:
		if not assigned_ok:
			Utils.temp_error_tooltip("Element already asigned to the player")
			return
	
	var entity_control_data := {
		"movement": false,
		"senses": false,
	}
	
	player_elements[element_selected.label] = entity_control_data
	Game.campaign.set_player_data(player_slug, player_data)
	
	create_child_element(element_selected.label, entity_control_data)

	Utils.sort_item_children(persmissions_tree.get_root())
	
	Game.server.rpcs.set_player_element_control.rpc(player_slug, element_selected.label, entity_control_data)
	
	Debug.print_info_message("Element \"%s\" asigned to player \"%s\"" % [element_selected.label, player_slug])


func _on_open_vision_button_pressed():
	var map := Game.ui.selected_map
	var level := map.selected_level
	var item_selected := players_tree.get_selected()
	if not item_selected or item_selected == players_tree.get_root():
		level.set_master_control()
		map.is_master_view = true
		reset_colors()
		Game.master_is_player = false
		return
	
	if Game.master_is_player:
		level.set_master_control()
		map.is_master_view = true
		reset_colors()
		Game.master_is_player = false
	else:
		level.set_control(Game.player.elements)
		map.is_master_view = false
		reset_colors()
		Game.master_is_player = true
		item_selected.set_custom_color(0, Color.GREEN)
		

func reset_colors():
	for item: TreeItem in player_items.values():
		item.clear_custom_color(0)
		

func _on_center_view_button_pressed():
	var players_map = Game.ui.tab_world.players_map
	if players_map != Game.ui.selected_map.slug:
		Utils.temp_error_tooltip("Players are not in this map")
		return
		
	var master_position := Game.ui.selected_map.camera.position_3d
	var master_rotation := Game.ui.selected_map.camera.rotation_3d
	var master_zoom := Game.ui.selected_map.camera.zoom
	print(master_position)
	print(Game.ui.selected_map.camera.position_2d)
	if Game.player:
		Game.server.rpcs.copy_master_camera.rpc(master_position, master_rotation, master_zoom, Game.player.slug)
	else:
		Game.server.rpcs.copy_master_camera.rpc(master_position, master_rotation, master_zoom)
	

func get_data():
	var players := {}
	for player_slug in player_items:
		players[player_slug] = player_items[player_slug].get_metadata(0)
	
	return players
