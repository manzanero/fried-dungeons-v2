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

@onready var new_button: Button = %NewButton
@onready var folders_button: Button = %FoldersButton
@onready var scan_button: Button = %ScanButton
@onready var name_line_edit: LineEdit = %NameLineEdit

@onready var tree: DraggableTree = %Tree

@onready var add_entity_button: Button = %AddEntityButton
@onready var open_vision_button: Button = %OpenVisionButton
@onready var center_view_button: Button = %CenterViewButton


var root: TreeItem :
	get: return tree.get_root()
var player_items: Array[TreeItem] :
	get: return root.get_children()

var player_selected_item: TreeItem :
	get: 
		var selected_item := tree.get_selected()
		return tree.get_selected() if selected_item in player_items else null

var player_selected_slug: String :
	get: return player_selected_item.get_tooltip_text(0) if player_selected_item else ""

var player_selected_item_data: Dictionary :
	get: return player_selected_item.get_metadata(0) if player_selected_item else {}

func get_player_slug(player_item: TreeItem) -> String:
	return player_item.get_tooltip_text(0)

func get_player_item(player_slug: String) -> TreeItem:
	for player_item in player_items:
		if player_slug == player_item.get_tooltip_text(0):
			return player_item
	return null

func get_player_item_data(player_slug: String) -> Dictionary:
	var player_item := get_player_item(player_slug)
	return player_item.get_metadata(0) if player_item else {}

func get_element_id(element_item: TreeItem) -> String:
	return element_item.get_tooltip_text(0)


func _ready() -> void:
	Game.manager.campaign_loaded.connect(refresh)
	Game.flow.changed.connect(func (): 
		if root:
			_set_flow(root, Game.flow.state)
	)
	
	new_button.pressed.connect(_on_new_button_pressed)
	folders_button.pressed.connect(_on_folders_button_pressed)
	scan_button.pressed.connect(_on_scan_button_pressed)
	name_line_edit.text_changed.connect(_on_filter_text_changed)
	
	tree.button_clicked.connect(_on_item_button_clicked)
	
	add_entity_button.pressed.connect(_on_add_entity_button_pressed)
	#open_vision_button.pressed.connect(_on_open_vision_button_pressed)
	#center_view_button.pressed.connect(_on_center_view_button_pressed)


func reset():
	tree.clear()
	tree.create_item()
	root.set_text(0, "All players")
	root.set_tooltip_text(0, " ")
	root.set_metadata(0, {})
	
	root.add_button(0, RESET_ICON, 0)
	root.add_button(0, PLAY_ICON, 1)
	root.add_button(0, PAUSE_ICON, 2)
	root.add_button(0, STOP_ICON, 3)
	root.set_button_color(0, 0, Game.TREE_BUTTON_OFF_COLOR)
	root.set_button_color(0, 1, Game.TREE_BUTTON_OFF_COLOR)
	root.set_button_color(0, 2, Game.TREE_BUTTON_OFF_COLOR)
	root.set_button_color(0, 3, Game.TREE_BUTTON_OFF_COLOR)


func _on_new_button_pressed():
	Game.ui.nav_bar.campaign_players_pressed.emit()

func _on_folders_button_pressed() -> void:
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(Game.campaign.players_path))

func _on_filter_text_changed():
	var filter := Utils.slugify(name_line_edit.text.to_lower())
	for item in player_items:
		var data: Dictionary = item.get_metadata(0)
		if filter and filter not in Utils.slugify(data.username.to_lower()):
			item.visible = false
		else:
			item.visible = true

func _on_scan_button_pressed():
	refresh()


func refresh():
	reset()
	
	var campaign_data: Dictionary = Game.campaign.load_campaign_data()
	var campaign_players: Dictionary = campaign_data.get("players", {})
	
	_set_flow(root, Game.flow.state)
	
	var player_slugs := DirAccess.get_directories_at(Game.campaign.players_path)
	for player_slug in player_slugs:
		var player_data := Game.campaign.get_player_data(player_slug)
		if player_data.get("is_steam_player", false) != Game.server.is_steam_game:
			continue
		
		# player static data
		var player_username: String = player_data.username
		var player_elements: Dictionary = player_data.get("elements", {})
		
		# player dinamic data
		var player_item_data: Dictionary = campaign_players.get(player_slug, {})
		var player_state: FlowController.State = player_item_data.get_or_add("state", FlowController.State.NONE)
		
		var player_item := root.create_child()
		player_item.set_text(0, player_username)
		player_item.set_icon(0, PLAYER_ICON)
		player_item.set_icon_modulate(0, Utils.html_color_to_color(player_data.get_or_add("color", "ffffff")))
		
		player_item.set_custom_color(0, Color.BROWN)
		player_item.set_tooltip_text(0, player_slug)
		player_item.set_metadata(0, player_item_data)
		
		# set buttons
		player_item.add_button(0, RESET_ICON, 0)
		player_item.set_button_color(0, 0, Game.TREE_BUTTON_OFF_COLOR)
		player_item.add_button(0, PLAY_ICON, 1)
		player_item.add_button(0, PAUSE_ICON, 2)
		player_item.add_button(0, STOP_ICON, 3)
		_set_flow(player_item, player_state)
		
		for element_id in player_elements:
			var element_control_data := {
				"movement": player_elements[element_id].get("movement", false),
				"senses": player_elements[element_id].get("senses", false),
			}
			create_child_element(player_item, element_id, element_control_data)


func create_child_element(player_item: TreeItem, element_id: String, element_control_data: Dictionary):
	var element_item := player_item.create_child()
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


func _on_item_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int):
	
	# all item
	var is_all_item := item == root
	if is_all_item:
		match id:
			0: reset_all_players()
			1: _set_flow(item, FlowController.State.PLAYING); Game.flow.play()
			2: _set_flow(item, FlowController.State.PAUSED); Game.flow.pause()
			3: _set_flow(item, FlowController.State.STOPPED); Game.flow.stop()
			
		Game.server.rpcs.change_flow_state.rpc(Game.flow.state, get_data())
		return
	
	# player item
	var is_player_item := item in player_items
	if is_player_item:
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
		
	# element item
	match id:
		0: _toggle_permission(item, Player.Permission.MOVEMENT)
		1: _toggle_permission(item, Player.Permission.SENSES)
		2: _clear_permisions(item)
		

func reset_all_players():
	_set_flow(root, Game.flow.state)
	for player_item in player_items:
		_set_flow(player_item, FlowController.State.NONE)


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


func _toggle_permission(item: TreeItem, permission: String):
	var element_id := get_element_id(item)
	var player_slug := get_element_id(item.get_parent())
	var player_data := Game.campaign.get_player_data(player_slug)
	var player_elements: Dictionary = player_data.get_or_add("elements", {})
	var element_control_data: Dictionary = player_elements.get_or_add(element_id, {})
	
	match permission:
		Player.Permission.MOVEMENT: 
			var allow_movement: bool = not element_control_data.get_or_add("movement", false)
			element_control_data[permission] = allow_movement
			item.set_button_color(0, 0, Color.WHITE if allow_movement else Game.TREE_BUTTON_OFF_COLOR)
		Player.Permission.SENSES: 
			var allow_senses: bool = not element_control_data.get_or_add("senses", false)
			element_control_data[permission] = allow_senses
			item.set_button_color(0, 1, Color.WHITE if allow_senses else Game.TREE_BUTTON_OFF_COLOR)
	
	Game.campaign.set_player_data(player_slug, player_data)
	
	Game.server.rpcs.set_player_element_control.rpc(player_slug, element_id, element_control_data)
	
	Debug.print_info_message("Entity \"%s\" %s added to player \"%s\"" % \
			[element_id, permission, player_selected_slug])


func _clear_permisions(item: TreeItem):
	var element_id := get_element_id(item)
	var player_slug := get_player_slug(item.get_parent())
	var player_data := Game.campaign.get_player_data(player_slug)
	player_data.elements.erase(element_id)
	Game.campaign.set_player_data(player_slug, player_data)
	
	item.free()
	
	Game.server.rpcs.clear_player_element_control.rpc(player_slug, element_id)
	
	

func _on_add_entity_button_pressed():
	var element_selected := Game.ui.selected_map.selected_level.element_selected; 
	if not is_instance_valid(element_selected) or element_selected is not Entity:
		Utils.temp_error_tooltip("Select an Entity to asign")
		return
	
	if not player_selected_item:
		Utils.temp_error_tooltip("Select the player to be asignted")
		return
		
	var player_selected_data := Game.campaign.get_player_data(player_selected_slug)
	var player_elements: Dictionary = player_selected_data.get_or_add("elements", {})
	if element_selected.id in player_elements:
		Utils.temp_error_tooltip("Element already asigned to the player")
		return
	
	var entity_control_data := {
		"movement": false,
		"senses": false,
	}
	
	player_elements[element_selected.id] = entity_control_data
	Game.campaign.set_player_data(player_selected_slug, player_selected_data)
	
	create_child_element(player_selected_item, element_selected.id, entity_control_data)
	
	Game.server.rpcs.set_player_element_control.rpc(player_selected_slug, element_selected.id, entity_control_data)
	
	Debug.print_info_message("Element \"%s\" asigned to player \"%s\"" % [element_selected.id, player_selected_slug])
	
	

func get_data():
	var players := {}
	for player_item in player_items:
		var player_slug := player_item.get_tooltip_text(0)
		var player_item_data: Dictionary = player_item.get_metadata(0)
		players[player_slug] = player_item_data
	
	return players
