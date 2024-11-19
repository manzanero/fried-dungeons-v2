class_name ServerManager
extends Node


signal player_connected(username)
signal player_disconnected(username)
signal server_disconnected

const PORT := 2020

@export var rpcs: Rpcs

var peer: ENetMultiplayerPeer
var server_address := "127.0.0.1"
var server_port := PORT
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
	if peer:
		peer.close()
		
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT)
	if error:
		Debug.print_error_message("create_server == %s" % error)
		return error
		
	multiplayer.multiplayer_peer = peer
	return OK
	

func join_multiplayer(host: String, username: String, password: String) -> Error:
	if peer:
		peer.close()
	
	peer = ENetMultiplayerPeer.new()
	server_address = host
	if host.split(":").size() == 2:
		server_address = host.split(":")[0]
		var port: String = host.split(":")[1]
		server_port =  port.to_int() if port.is_valid_int() else PORT
	var error := peer.create_client(server_address, server_port)
	if error:
		Debug.print_error_message("create_client == %s" % error)
		return error
	
	player_username = username
	player_password = password
	multiplayer.multiplayer_peer = peer
	return OK
	

func _on_player_connected(id: int):
	Debug.print_info_message("Player connected: %s" % id)
	
	# introduce yourself to the master
	if not multiplayer.is_server():
		_register_player.rpc_id(id, player_username, player_password)


@rpc("any_peer", "reliable")
func _register_player(username: String, password: String):
	var new_player_id := multiplayer.get_remote_sender_id()
	players[username] = new_player_id
	
	# master accomodates new player
	if multiplayer.is_server():
		if _is_player_registered(username, password):
			set_up_player(new_player_id)
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
	server_disconnected.emit()
		
	Game.manager.reset()


func _on_server_disconnected():
	Debug.print_info_message("Server disconnected")
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
		
	Game.manager.reset()
	

## rpcs

func _is_player_registered(username, password) -> bool:
	Debug.print_info_message("New Player login: %s" % username)
	var username_slug := Utils.slugify(username)
	var campaign := Game.ui.tab_players.campaign_selected
	
	if username_slug in campaign.players:
		for player_slug in campaign.players:
			var player_data := campaign.get_player_data(player_slug)
			if username == player_data.username and password == player_data.password:
				return true
			
	Debug.print_info_message("Player login failed: %s" % username)
	return false


func set_up_player(id: int):
	Debug.print_info_message("Setting up player %s" % id)
	var campaign := Game.campaign
	var campaign_data := campaign.json()
	load_campaign.rpc_id(id, campaign.slug, campaign_data)


@rpc("any_peer", "reliable")
func load_campaign(campaign_slug: String, campaign_data: Dictionary):
	Debug.print_info_message("Loading campaign %s" % campaign_slug)
	Game.campaign = Campaign.new(false, campaign_data.label, campaign_data.imports)
	Game.manager.reset()
	
	var server_path := Game.campaign.campaign_path
	Utils.make_dirs(server_path.path_join("resources"))
	var server_error := Utils.dump_json(server_path.path_join("server.json"), {
		"label": campaign_data.label,
		"host": server_address,
	}, 2)
	if server_error:
		Debug.print_error_message("Failed to create Server file")
		
	var player_path := server_path.path_join("players").path_join(Utils.slugify(player_username))
	Utils.make_dirs(player_path)
	var player_error := Utils.dump_json(player_path.path_join("player.json"), {
		"username": player_username,
		"password": player_password,
	}, 2)
	if player_error:
		Debug.print_error_message("Failed to create Player file")

	# init jukebox
	for sound_data in campaign_data.jukebox.sounds:
		var sound := Game.manager.get_resource(CampaignResource.Type.SOUND, sound_data.sound)
		if not sound.loaded:
			await sound.resource_loaded
		var from_position: float = sound_data.get("position", 0.0)
		Game.ui.tab_jukebox.add_sound(sound, sound_data.loop, from_position)
	
	Game.flow.change_flow_state(campaign_data.state)
	
	request_map.rpc_id(1, campaign_data.players_map)


@rpc("any_peer", "reliable")
func request_map_notification(map_slug: String):
	request_map.rpc_id(1, map_slug)


@rpc("any_peer", "reliable")
func request_map(map_slug: String):
	Debug.print_info_message("Requested map %s" % map_slug)
	var id := multiplayer.get_remote_sender_id()
	var map: Map = Game.maps.get(map_slug)
	var map_data: Dictionary = map.json()
	
	load_map.rpc_id(id, map_slug, map_data)


@rpc("any_peer", "reliable")
func load_map(map_slug: String, map_data: Dictionary):
	Debug.print_info_message("Loading map %s" % map_slug)
	
	if not Game.ui.selected_map or map_slug != Game.ui.selected_map.slug:
		for scene_tab in Game.ui.scene_tabs.get_children():
			scene_tab.remove()
		
		const TAB_SCENE = preload("res://ui/tabs/tab_scene/tab_scene.tscn")
		var tab_scene: TabScene = TAB_SCENE.instantiate().init(map_slug, map_data)
		tab_scene.map.is_master_view = false
		tab_scene.map.current_ambient_light = tab_scene.map.ambient_light
		tab_scene.map.current_ambient_color = tab_scene.map.ambient_color
	
	request_player.rpc_id(1, Utils.slugify(player_username))


@rpc("any_peer", "reliable")
func request_player(player_slug: String):
	Debug.print_info_message("Requested player %s" % player_slug)
	var id := multiplayer.get_remote_sender_id() 
	var player_data := Game.campaign.get_player_data(player_slug)
	load_player.rpc_id(id, player_slug, player_data)


@rpc("any_peer", "reliable")
func load_player(player_slug: String, player_data: Dictionary):
	Debug.print_info_message("Loading player %s" % player_slug)
	Game.player = Player.load(player_data)
	
	for element in Game.ui.selected_map.selected_level.elements:
		if element is Entity:
			element.eye.visible = false
	
	for entity_id in Game.player.entities:
		var entity: Entity = Game.ui.selected_map.selected_level.elements.get(entity_id)
		if entity:
			entity.eye.visible = true
			entity.is_selectable = true
			Game.ui.selected_map.camera.position_2d = entity.position_2d
			Debug.print_info_message("Player \"%s\" got control of \"%s\"" % [player_slug, entity_id])


@rpc("any_peer", "reliable")
func request_resource(resource_path: String):
	Debug.print_info_message("Requested resource %s" % resource_path)
	var id := multiplayer.get_remote_sender_id() 
	var resource_abspath := Game.campaign.resources_path.path_join(resource_path)
	var resource_bytes := FileAccess.get_file_as_bytes(resource_abspath)
	if not resource_bytes:
		Debug.print_error_message("Requested resource %s not found" % resource_abspath)
		return
	
	var import_data = Game.ui.tab_instancer.resources[resource_path].import_data
	load_resource.rpc_id(id, resource_bytes, resource_path, import_data)


@rpc("any_peer", "reliable")
func load_resource(resource_bytes: PackedByteArray, resource_path: String, import_data: Dictionary):
	Debug.print_info_message("Requested resource %s" % resource_path)
	var resource_abspath := Game.campaign.resources_path.path_join(resource_path)
	Utils.make_dirs(resource_abspath.get_base_dir())
	var resource_file := FileAccess.open(resource_abspath, FileAccess.WRITE)
	resource_file.store_buffer(resource_bytes)
	
	var resource: CampaignResource = Game.ui.tab_instancer.resources[resource_path]
	resource.import_data = import_data
	resource.loaded = true
