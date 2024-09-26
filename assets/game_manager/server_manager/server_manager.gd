class_name ServerManager
extends Node


signal player_connected(username)
signal player_disconnected(username)
signal server_disconnected

const PORT := 25565

@export var rpcs: Rpcs

var peer := ENetMultiplayerPeer.new()
var player_id := 1
var player_username := "Unnamed"
var player_password := ""
var players = {}


func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host_multiplayer() -> Error:
	var retries := 3
	for i in range(retries):
		var error := peer.create_server(PORT)
		if not error:
			break
		
		if i < retries - 1:
			Debug.print_warning_message("create_server == %s" % error)
		else:
			Debug.print_error_message("create_server == %s" % error)
			return error
		
	multiplayer.multiplayer_peer = peer
	return OK
	

func join_multiplayer(server_data: Dictionary) -> Error:
	var error := peer.create_client(server_data.host, PORT)
	if error:
		Debug.print_error_message("create_client == %s" % error)
		return error
	
	player_username = server_data.username
	player_password = server_data.password
	multiplayer.multiplayer_peer = peer
	return OK
	

func _on_player_connected(id: int):
	Debug.print_info_message("Player connected: %s" % id)
	
	# introduce to the master
	if not multiplayer.is_server():
		_register_player.rpc_id(id, player_username, player_password)


@rpc("any_peer", "reliable")
func _register_player(username: String, password: String):
	var new_player_id := multiplayer.get_remote_sender_id()
	players[username] = new_player_id
	
	# master accomodates new player
	if multiplayer.is_server():
		if _is_player_registered(username, password):
			_set_up_player(new_player_id, username)
		else:
			peer.disconnect_peer(new_player_id)


func _on_player_disconnected(id):
	Debug.print_info_message("Player disconnected: %s" % id)
	players.erase(id)
	player_disconnected.emit(player_username)


func _on_connected_ok():
	Debug.print_info_message("Server connected")
	player_id = multiplayer.get_unique_id()
	
	Debug.id = player_id
	players[player_username] = player_id
	player_connected.emit(player_username)


func _on_connected_fail():
	Debug.print_info_message("Connected fail")
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit(player_username)


func _on_server_disconnected():
	Debug.print_info_message("Server disconnected")
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
	

## rpcs

func _is_player_registered(username, password) -> bool:
	Debug.print_info_message("Player login: %s" % username)
	var player_slug := Utils.slugify(username)
	var campaign := Game.ui.tab_players.campaign_selected
	
	if not player_slug in campaign.players:
		Debug.print_info_message("Player login failed: %s" % username)
		return false
	
	if not password == campaign.get_player(player_slug).password:
		Debug.print_info_message("Player login failed: %s" % username)
		return false
	
	return true


func _set_up_player(id: int, username: String):
	Debug.print_info_message("Setting up player %s" % id)
	var campaign := Game.campaign
	_load_campaign.rpc_id(id, campaign.slug, campaign.json)
	var map := Game.ui.selected_map
	_load_map.rpc_id(id, map.slug, map.json())
	var player_slug := Utils.slugify(username)
	var player := Game.campaign.get_player(player_slug)
	_load_player.rpc_id(id, player_slug, player)


@rpc("any_peer", "reliable")
func _load_campaign(campaign_slug: String, campaign_data: Dictionary):
	Debug.print_info_message("Loading campaign %s" % campaign_slug)
	Game.campaign = Campaign.new()
	Game.campaign.label = campaign_data.label


const TAB_SCENE = preload("res://ui/tabs/tab_scene/tab_scene.tscn")

@rpc("any_peer", "reliable")
func _load_map(map_slug: String, map_data: Dictionary):
	Debug.print_info_message("Loading map %s" % map_slug)
	var tab_scene: TabScene = TAB_SCENE.instantiate().init(map_slug, map_data)
	tab_scene.map.is_master_view = false
	tab_scene.map.current_ambient_light = tab_scene.map.ambient_light
	tab_scene.map.current_ambient_color = tab_scene.map.ambient_color
	get_tree().set_group("lights", "hidden", true)


@rpc("any_peer", "reliable")
func _load_player(player_slug: String, player_data: Dictionary):
	Debug.print_info_message("Loading player %s" % player_slug)
	Game.player = Player.load(player_data)
	for entity_id in Game.player.entities:
		var entity: Entity = Game.ui.selected_map.selected_level.elements.get(entity_id)
		if entity:
			entity.eye.visible = true
			Debug.print_info_message("Player \"%s\" got control of \"%s\"" % [player_slug, entity_id])
