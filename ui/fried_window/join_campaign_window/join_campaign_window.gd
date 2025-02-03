class_name JoinCampaignWindow
extends FriedWindow

signal steam_campaign_joined(lobby_id: int)
signal enet_campaign_joined(host: String, username: String, password: String)


const PLAY_ICON := preload("res://resources/icons/play_icon.png")
const FOLDER_ICON := preload("res://resources/icons/directory_icon.png")
const REMOVE_ICON := preload("res://resources/icons/cross_icon.png")


@onready var steam_button: Button = %SteamButton
@onready var enet_button: Button = %EnetButton

@onready var steam_container: Control = %SteamContainer
@onready var host_steam_line_edit: LineEdit = %HostSteamLineEdit
@onready var steam_connect_button: Button = %SteamConnectButton
@onready var steam_filter_line_edit: LineEdit = %SteamFilterLineEdit
@onready var steam_refresh_button: Button = %SteamRefreshButton
@onready var steam_tree: DraggableTree = %SteamTree

@onready var enet_container: Control = %EnetContainer
@onready var host_line_edit: LineEdit = %HostLineEdit
@onready var username_line_edit: LineEdit = %UsernameLineEdit
@onready var password_line_edit: LineEdit = %PasswordLineEdit
@onready var enet_connect_button: Button = %EnetConnectButton
@onready var enet_filter_line_edit: LineEdit = %EnetFilterLineEdit
@onready var enet_refresh_button: Button = %EnetRefreshButton
@onready var enet_tree: DraggableTree = %EnetTree


var servers_path := "user://servers"
var steam_root: TreeItem
var enet_root: TreeItem

var steam_lobbies := {}
var steam_items: Array[TreeItem] = []
var enet_items: Array[TreeItem] = []


func _ready() -> void:
	super._ready()
	
	if Game.server.is_steam_ready:
		steam_button.button_pressed = true
		steam_container.visible = true
		enet_container.visible = false
	else:
		enet_button.button_pressed = true
		steam_button.disabled = true
		steam_container.visible = false
		enet_container.visible = true

	steam_button.pressed.connect(func (): 
		steam_container.visible = true
		enet_container.visible = false
	)
	enet_button.pressed.connect(func (): 
		steam_container.visible = false
		enet_container.visible = true
	)
	
	## steam
	steam_connect_button.pressed.connect(_on_steam_connect_button_pressed)
	
	steam_filter_line_edit.text_changed.connect(_on_steam_filter_changed.unbind(1))
	steam_refresh_button.pressed.connect(steam_refresh)
	
	steam_tree.set_column_title(0, "Mastered by      ")
	steam_tree.set_column_title(1, "Title")
	steam_tree.set_column_expand(0, false)
	steam_tree.set_column_expand(1, true)
	steam_tree.set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
	steam_tree.set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_LEFT)
	
	steam_tree.item_selected.connect(_on_steam_item_selected)
	steam_tree.item_activated.connect(_on_steam_item_activated)
	steam_tree.button_clicked.connect(_on_steam_item_button_clicked)

	Game.server.lobbies_loaded.connect(_on_lobbies_loaded)

	## enet
	Utils.make_dirs(servers_path)
	
	enet_connect_button.pressed.connect(_on_enet_connect_button_pressed)
	
	enet_filter_line_edit.text_changed.connect(_on_enet_filter_changed.unbind(1))
	enet_refresh_button.pressed.connect(enet_refresh)
	
	enet_tree.columns = 2
	enet_tree.set_column_title(0, "Played As        ")
	enet_tree.set_column_title(1, "Title")
	enet_tree.set_column_expand(0, false)
	enet_tree.set_column_expand(1, true)
	enet_tree.set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
	enet_tree.set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_LEFT)
	
	enet_tree.item_selected.connect(_on_enet_item_selected)
	enet_tree.item_activated.connect(_on_enet_item_activated)
	enet_tree.button_clicked.connect(_on_enet_item_button_clicked)
	

func _on_steam_connect_button_pressed():
	var host_username := host_steam_line_edit.text
	load_lobbies(host_username)
	await Game.server.lobbies_loaded
	
	if steam_lobbies:
		var lobby_id = steam_lobbies[host_username]
		Game.server.owner_steam_username = host_username
		steam_campaign_joined.emit(lobby_id)
		_on_close_button_pressed()
	else:
		Utils.temp_error_tooltip("Host is not connected")


func _on_enet_connect_button_pressed():
	enet_campaign_joined.emit(host_line_edit.text, username_line_edit.text, password_line_edit.text)
	_on_close_button_pressed()


func refresh():
	steam_refresh()
	enet_refresh()


func _on_steam_filter_changed():
	var filter := steam_filter_line_edit.text.to_lower()
	for item in steam_items:
		var server_data: Dictionary = item.get_metadata(0)
		if filter and filter not in server_data.label.to_lower():
			item.visible = false
		else:
			item.visible = true

func _on_enet_filter_changed():
	var filter := enet_filter_line_edit.text.to_lower()
	for item in enet_items:
		var server_data: Dictionary = item.get_metadata(1)
		if filter and filter not in server_data.label.to_lower():
			item.visible = false
		else:
			item.visible = true
		

func _on_steam_item_activated():
	var server_data: Dictionary = steam_tree.get_selected().get_metadata(1)
	var host_username = server_data.host
	
	load_lobbies(host_username)
	await Game.server.lobbies_loaded

	if steam_lobbies:
		var lobby_id = steam_lobbies[host_username]
		Game.server.owner_steam_username = host_username
		steam_campaign_joined.emit(lobby_id)
		_on_close_button_pressed()
	else:
		Utils.temp_error_tooltip("Host is not connected")
		
func _on_steam_item_selected():
	var server_data: Dictionary = steam_tree.get_selected().get_metadata(1)
	var host_username = server_data.host
	host_steam_line_edit.text = host_username


func _on_enet_item_activated():
	var server_data: Dictionary = enet_tree.get_selected().get_metadata(1)
	var player_username: String = server_data.get("username", "Anonymous")
	var player_password: String = server_data.get("password", "")
	enet_campaign_joined.emit(server_data.host, player_username, player_password)
	_on_close_button_pressed()

func _on_enet_item_selected():
	var server_data: Dictionary = enet_tree.get_selected().get_metadata(1)
	var player_username: String = server_data.get("username", "Anonymous")
	var player_password: String = server_data.get("password", "")
	host_line_edit.text = server_data.host
	username_line_edit.text = player_username
	password_line_edit.text = player_password


func _on_steam_item_button_clicked(steam_item: TreeItem, _column: int, id: int, _mouse_button_index: int):
	steam_item.select(0)
	var server_slug: String = steam_item.get_metadata(0)
	var server_path := servers_path.path_join(server_slug)
	match id:
		0: 
			_on_steam_item_activated()
		1: 
			Utils.open_in_file_manager(server_path)
		2: 
			Utils.remove_dirs(server_path)
			steam_refresh()


func _on_enet_item_button_clicked(enet_item: TreeItem, _column: int, id: int, _mouse_button_index: int):
	enet_item.select(0)
	var server_folder: String = enet_item.get_metadata(0)
	var server_path := servers_path.path_join(server_folder)
	match id:
		0: 
			_on_enet_item_activated()
		1: 
			Utils.open_in_file_manager(server_path)
		2: 
			Utils.remove_dirs(server_path)
			enet_refresh()


func load_lobbies(host_username: String):
	Steam.addRequestLobbyListStringFilter("host", host_username, Steam.LobbyComparison.LOBBY_COMPARISON_EQUAL)
	Steam.addRequestLobbyListDistanceFilter(Steam.LobbyDistanceFilter.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()
	
	
func _on_lobbies_loaded(lobbies_list: Array):
	steam_lobbies.clear()
	for lobby_id in lobbies_list:
		var lobby_data: Dictionary = _lobby_data_to_dict(Steam.getAllLobbyData(lobby_id))
		steam_lobbies[lobby_data.host] = lobby_id
		
	
func _lobby_data_to_dict(all_lobby_data: Dictionary) -> Dictionary:
	var dict := {}
	for lobby_data in all_lobby_data:
		dict[all_lobby_data[lobby_data].key.to_lower()] = all_lobby_data[lobby_data].value
	return dict


func steam_refresh():
	steam_tree.clear()
	steam_items.clear()
	steam_root = steam_tree.create_item()
	
	var filter := enet_filter_line_edit.text.to_lower()
	
	var server_slugs := DirAccess.get_directories_at(servers_path)
	Debug.print_info_message("Servers: %s" % str(server_slugs))
	
	for server_slug in server_slugs:
		var server_path := servers_path.path_join(server_slug)
		var server_data := Utils.load_json(server_path.path_join("server.json"))
		if not server_data.get("is_steam_game", false):
			continue
			
		var server_label: String = server_data.label
		var server_host: String = server_data.host
		
		var item := steam_root.create_child()
		
		if filter and filter not in server_data.label.to_lower():
			item.visible = false
		else:
			item.visible = true
		
		item.set_text(0, server_host)
		item.set_tooltip_text(0, " ")
		item.set_text(1, server_label)
		item.set_tooltip_text(1, server_slug)
		
		item.add_button(1, PLAY_ICON, 0)
		item.set_button_color(1, 0, Color.DARK_GRAY)
		item.add_button(1, FOLDER_ICON, 1)
		item.set_button_color(1, 1, Color.GOLDENROD)
		item.add_button(1, REMOVE_ICON, 2)
		item.set_button_color(1, 2, Color.RED)
		item.set_metadata(0, server_slug)
		item.set_metadata(1, server_data)
		
		steam_items.append(item)


func enet_refresh():
	enet_tree.clear()
	enet_items.clear()
	enet_root = enet_tree.create_item()
	host_line_edit.clear()
	username_line_edit.clear()
	password_line_edit.clear()
	
	var filter := enet_filter_line_edit.text.to_lower()
	
	var server_slugs := DirAccess.get_directories_at(servers_path)
	Debug.print_info_message("Servers: %s" % str(server_slugs))
	
	for server_slug in server_slugs:
		var server_path := servers_path.path_join(server_slug)
		var server_data := Utils.load_json(server_path.path_join("server.json"))
		if server_data.get("is_steam_game", false):
			continue
			
		var server_label: String = server_data.label
		var username_label: String = server_data.get("username", "Anonymous")
		
		var item := enet_root.create_child()
		
		if filter and filter not in server_data.label.to_lower():
			item.visible = false
		else:
			item.visible = true
		
		item.set_text(0, username_label)
		item.set_tooltip_text(0, " ")
		item.set_text(1, server_label)
		item.set_tooltip_text(1, server_slug)
		
		item.add_button(1, PLAY_ICON, 0)
		item.set_button_color(1, 0, Color.DARK_GRAY)
		item.add_button(1, FOLDER_ICON, 1)
		item.set_button_color(1, 1, Color.GOLDENROD)
		item.add_button(1, REMOVE_ICON, 2)
		item.set_button_color(1, 2, Color.RED)
		
		item.set_metadata(0, server_slug)
		item.set_metadata(1, server_data)
		
		enet_items.append(item)
