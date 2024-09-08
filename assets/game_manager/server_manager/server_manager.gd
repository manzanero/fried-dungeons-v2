class_name ServerManager
extends Node


signal player_connected(player_name)
signal player_disconnected(player_name)
signal server_disconnected


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
		return error
	multiplayer.multiplayer_peer = peer
	
	players[Game.player_name] = 1
	

func join_multiplayer(host: String):
	var error := peer.create_client(host, 2020)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	

func _on_player_connected(id: int):
	_register_player.rpc_id(id, Game.player_name)


@rpc("any_peer", "reliable")
func _register_player(player_name: String):
	var new_player_id := multiplayer.get_remote_sender_id()
	
	players[player_name] = new_player_id
	player_connected.emit(player_name)


func _on_player_disconnected(id):
	players.erase(id)
	player_disconnected.emit(id)


func _on_connected_ok():
	player_id = multiplayer.get_unique_id()
	
	players[Game.player_name] = player_id
	player_connected.emit(Game.player_name)


func _on_connected_fail():
	multiplayer.multiplayer_peer = null


func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
	
	
@rpc("any_peer", "reliable")
func add_operation(opertation: Dictionary):
	print(opertation, player_id)
