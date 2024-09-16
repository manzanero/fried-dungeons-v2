class_name ServerManager
extends Node


signal player_connected(player_name)
signal player_disconnected(player_name)
signal server_disconnected

@export var rpcs: Rpcs

var peer := ENetMultiplayerPeer.new()
var player_id := 1
var players = {}


func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host_multiplayer():
	var error := peer.create_server(2020)
	if error:
		Debug.print_error_message("create_server == %s" % error)
		return error
	multiplayer.multiplayer_peer = peer
	
	players[Game.player_name] = 1
	

func join_multiplayer(host: String):
	var error := peer.create_client(host, 2020)
	if error:
		Debug.print_error_message("create_client == %s" % error)
		return error
	multiplayer.multiplayer_peer = peer
	

func _on_player_connected(id: int):
	Debug.print_info_message("Player connected: %s" % id)
	_register_player.rpc_id(id, Game.player_name)
	if multiplayer.is_server():
		set_up_player(id)


@rpc("any_peer", "reliable")
func _register_player(player_name: String):
	var new_player_id := multiplayer.get_remote_sender_id()
	
	players[player_name] = new_player_id
	player_connected.emit(player_name)


func _on_player_disconnected(id):
	Debug.print_info_message("Player disconnected: %s" % id)
	players.erase(id)
	player_disconnected.emit(id)


func _on_connected_ok():
	Debug.print_info_message("Server connected")
	player_id = multiplayer.get_unique_id()
	
	Debug.id = player_id
	players[Game.player_name] = player_id
	player_connected.emit(Game.player_name)


func _on_connected_fail():
	multiplayer.multiplayer_peer = null


func _on_server_disconnected():
	Debug.print_info_message("Server disconnected")
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
	

## rpcs

func set_up_player(id):
	Debug.print_info_message("Setting up player %s" % id)
	var campaign := Game.campaign
	_load_campaign.rpc_id(id, campaign.slug, campaign.json)
	var map := Game.ui.selected_map
	_load_map.rpc_id(id, map.slug, map.json())


@rpc("any_peer", "reliable")
func _load_campaign(campaign_slug: String, campaign_data: Dictionary):
	Debug.print_info_message("Loading campaign %s" % campaign_slug)
	Game.campaign = Campaign.new()
	Game.campaign.label = campaign_data.label


const TAB_SCENE = preload("res://ui/tabs/tab_scene/tab_scene.tscn")

@rpc("any_peer", "reliable")
func _load_map(map_slug: String, map_data: Dictionary):
	Debug.print_info_message("Loading map %s" % map_slug)
	var _tab_scene: TabScene = TAB_SCENE.instantiate().init(map_slug, map_data)
