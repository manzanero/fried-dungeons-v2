class_name ServerManager
extends Node


signal presence_connected(presence: Presence)
signal presence_disconnected(presence: Presence)
signal server_disconnected

# Steam
signal lobbies_loaded(lobbies_list: Array)


const PORT := 2020
const MAX_PEERS := 16
const APP_ID = 3352000


@export var rpcs: Rpcs

var peer: MultiplayerPeer :
	set(value): 
		if peer: 
			peer.close()
			multiplayer.multiplayer_peer = null
		peer = value
		

var is_peer_connected: bool :
	get: return peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED if peer else false

var presence := Presence.new(-1, "Unnamed", "unnamed")
var presences: Array[Presence] = []

class Presence:
	var id: int
	var username: String
	var slug: String
	
	func _init(_id: int, _username: String, _slug: String) -> void:
		id = _id
		username = _username
		slug = _slug

var is_steam_game := false

## enet
var enet_host := "127.0.0.1"
var enet_port := PORT
var enet_username: String
var enet_password: String

## steam
var is_steam_ready := false
var lobby_id := 0
var owner_steam_id := -1
var owner_steam_username := ""
var is_online: bool
var is_owned: bool
var steam_id: int
var steam_username: String


func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	## Steam
	var steam_init_response: Dictionary = Steam.steamInitEx(true, APP_ID)
	var steam_error: int = steam_init_response['status']
	if steam_error:
		is_steam_ready = false
		Debug.print_error_message("Failed to initialize Steam: %s" % steam_init_response['verbal'])
	else:
		is_steam_ready = true
		is_online = Steam.loggedOn()
		is_owned = Steam.isSubscribed()
		steam_id = Steam.getSteamID()
		steam_username = Steam.getPersonaName()
		Debug.print_info_message("Steam connected")
		
		Steam.lobby_created.connect(_on_lobby_created)
		Steam.lobby_joined.connect(_on_lobby_joined)
		Steam.lobby_match_list.connect(_on_lobby_match_list)
		Steam.lobby_kicked.connect(Debug.print_info_message.bind("Lobby kicked %s" % lobby_id))


func _process(_delta):
	Steam.run_callbacks()
	

func host_multiplayer(steam: bool) -> Error:
	if lobby_id:
		delete_lobby(lobby_id)
		lobby_id = 0
		
	if steam:
		return host_steam_multiplayer()
	else:
		return host_enet_multiplayer()
	

func delete_lobby(_lobby_id):
	Debug.print_info_message("Leaving Lobby %s" % _lobby_id)
	if steam_id == Steam.getLobbyOwner(_lobby_id):
		leave_lobby(_lobby_id)
	Steam.leaveLobby(_lobby_id)


# player
@rpc("any_peer", "reliable")
func leave_lobby(_lobby_id):
	Steam.leaveLobby(_lobby_id)


func host_steam_multiplayer():
	Debug.print_info_message("Creating Lobby")

	presence.username = steam_username
	presence.slug = str(steam_id)
	
	is_steam_game = true
	
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, MAX_PEERS)
	#Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, MAX_PEERS)
	
	return OK


func _on_lobby_created(_connect: int, _lobby_id: int):
	if _connect != 1:
		Debug.print_error_message("Error on create lobby!")
		return
	
	Debug.print_info_message("Creating lobby id: %s" % _lobby_id)
	
	lobby_id = _lobby_id
	Steam.setLobbyJoinable(_lobby_id, true)
	Steam.setLobbyData(_lobby_id, "label", Game.campaign.label)
	Steam.setLobbyData(_lobby_id, "slug", Game.campaign.slug)
	Steam.setLobbyData(_lobby_id, "host", steam_username)
	Steam.setLobbyData(_lobby_id, "time", Time.get_time_string_from_system())
	
	peer = SteamMultiplayerPeer.new()
	peer.create_host(0)
	multiplayer.multiplayer_peer = peer


func join_steam_multiplayer(_lobby_id: int):
	if lobby_id:
		delete_lobby(lobby_id)
		
	Debug.print_info_message("Joining lobby id: %s" % _lobby_id)
	
	presence.username = steam_username
	presence.slug = Utils.slugify(steam_username)
	#presence.slug = str(steam_id)
	
	is_steam_game = true
	
	Steam.joinLobby(_lobby_id)


func _on_lobby_joined(_lobby_id: int, _permissions: int, _locked: bool, response: int):
	if response != 1:
		Debug.print_error_message({
			2: "This lobby no longer exists",
			3: "You don't have permission to join this lobby",
			4: "The lobby is now full",
			5: "Uh... something unexpected happened!",
			6: "You are banned from this lobby",
			7: "You cannot join due to having a limited account",
			8: "This lobby is locked or disabled",
			9: "This lobby is community locked",
			10: "A user in the lobby has blocked you from joining",
			11: "A user you have blocked is in the lobby",
		}[response])
		return
	
	lobby_id = _lobby_id
	owner_steam_id = Steam.getLobbyOwner(_lobby_id)
	if owner_steam_id == Steam.getSteamID():
		Debug.print_info_message("You already own the lobby")
		return
	
	Debug.print_info_message("Joined lobby id: %s" % _lobby_id)
	peer = SteamMultiplayerPeer.new()
	peer.create_client(owner_steam_id, 0)
	
	while not is_peer_connected:
		Debug.print_info_message("peer not connected. Retrying in 3 seconds")
		await get_tree().create_timer(3).timeout
		
	multiplayer.multiplayer_peer = peer
	is_steam_game = true


func request_steam_lobbies():
	Debug.print_info_message("Requesting Steam Lobbies")
	
	#Steam.addRequestLobbyListDistanceFilter(Steam.LobbyDistanceFilter.LOBBY_DISTANCE_FILTER_DEFAULT)
	Steam.addRequestLobbyListDistanceFilter(Steam.LobbyDistanceFilter.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()
	

func _on_lobby_match_list(lobbies: Array):
	Debug.print_info_message("Steam Lobbies received")
	
	lobbies_loaded.emit(lobbies)


func host_enet_multiplayer() -> Error:
	if lobby_id:
		delete_lobby(lobby_id)
		lobby_id = 0
	
	Debug.print_info_message("Creating server at port %s" % PORT)
	peer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(PORT)
	if error:
		Debug.print_error_message("create_server == %s" % error)
		return error
		
	is_steam_game = false
		
	multiplayer.multiplayer_peer = peer
	return OK


func join_enet_multiplayer(host: String, username: String, password: String) -> Error:
	if lobby_id:
		delete_lobby(lobby_id)
		lobby_id = 0
		
	peer = ENetMultiplayerPeer.new()
	enet_host = host
	if host.split(":").size() == 2:
		enet_host = host.split(":")[0]
		var port: String = host.split(":")[1]
		enet_port =  port.to_int() if port.is_valid_int() else PORT
	var error: Error = peer.create_client(enet_host, enet_port)
	if error:
		Debug.print_error_message("create_client == %s" % error)
		return error
	
	presence.username = username
	presence.slug = Utils.slugify(username)
	enet_username = username
	enet_password = password
	
	is_steam_game = false
	
	multiplayer.multiplayer_peer = peer
	Debug.print_info_message("Enet client created")
	return OK


func _on_player_connected(id: int):
	Debug.print_info_message("Player connected: %s" % id)
	
	## introduce yourself to the master
	if not multiplayer.is_server():
		if is_steam_game:
			_register_steam_player.rpc_id(1, presence.username, steam_id)
		else:
			_register_enet_player.rpc_id(1, presence.username, enet_password)


# master
@rpc("any_peer", "reliable")
func _register_steam_player(username: String, _steam_id: int):
	Debug.print_info_message("Player registration: %s" % username)
	
	var new_player_id := multiplayer.get_remote_sender_id()
	var slug := Utils.slugify(username)
	#var slug := str(_steam_id)
	var error_reason := "Player %s not in campaign" % username
		
	if slug not in Game.campaign.players:
		Debug.print_info_message("Player not welcome (slug): %s" % username)
		steam_disconnect.rpc_id(new_player_id, error_reason)
		return
		
	if Game.campaign.get_player_data(slug).username != username:
		Debug.print_info_message("Player not welcome (username): %s" % username)
		steam_disconnect.rpc_id(new_player_id, error_reason)
		return
	
	var new_presence := Presence.new(new_player_id, username, slug)
	presences.append(new_presence)
	
	load_campaign.rpc_id(new_player_id, Game.campaign.slug, Game.campaign.json(), true)
	Debug.print_info_message("Steam Player registered: %s" % new_player_id)


# player
@rpc("any_peer", "reliable")
func steam_disconnect(reason: String):  # disconnect_peer(id) does not work for steam
	Debug.print_error_message(reason)  
	peer = null
	
	
# master
@rpc("any_peer", "reliable")
func _register_enet_player(username: String, password: String):
	Debug.print_info_message("Player registration: %s" % username)
	
	var new_player_id := multiplayer.get_remote_sender_id()
	var slug := Utils.slugify(username)
	
	if not _is_player_registered(username, password):
		Debug.print_info_message("Player registration: %s" % username)
		peer.disconnect_peer(new_player_id)
		return
	
	var new_presence := Presence.new(new_player_id, username, slug)
	presences.append(new_presence)
	
	load_campaign.rpc_id(new_player_id, Game.campaign.slug, Game.campaign.json(), false)
	Debug.print_info_message("Player registered: %s" % new_player_id)

# master
func _is_player_registered(username, password) -> bool:
	Debug.print_info_message("New Player login: %s" % username)
	var campaign := Game.campaign
	
	if Utils.slugify(username) in Game.campaign.players:
		for slug in Game.campaign.players:
			var player_data := Game.campaign.get_player_data(slug)
			if username == player_data.username and password == player_data.password:
				return true
			
	Debug.print_info_message("Player login failed: %s" % username)
	return false


func _on_player_disconnected(id):
	Debug.print_info_message("Player disconnected: %s" % id)
	for p in presences:
		if p.id == id:
			presences.erase(p)
	presence_disconnected.emit(presence)


func _on_connected_ok():
	Debug.print_info_message("Server connected")
	
	presence.id = multiplayer.get_unique_id()
	Debug.id = presence.id
	presence_connected.emit(presence)


func _on_connected_fail():
	Debug.print_info_message("Connected fail")
	if multiplayer:
		multiplayer.multiplayer_peer = null
	presences.clear()
	server_disconnected.emit()


func _on_server_disconnected():
	Debug.print_info_message("Server disconnected")
	if multiplayer:
		multiplayer.multiplayer_peer = null
	presences.clear()
	server_disconnected.emit()


## rpcs

# player
@rpc("any_peer", "reliable")
func load_campaign(campaign_slug: String, campaign_data: Dictionary, is_steam_campaign := false):
	Debug.print_info_message("Loading campaign %s" % campaign_slug)
	Game.master = Player.new("master", campaign_data.get("master", {}))
	Game.campaign = Campaign.new(false, campaign_slug, campaign_data)
	Game.manager.reset()
	
	if is_steam_campaign:
		if Game.campaign.save_server_data({
			"is_steam_game": is_steam_campaign,
			"label": campaign_data.label,
			"host": owner_steam_username,
		}):
			Debug.print_error_message("Failed to create Server file")
	
	else:
		if Game.campaign.save_server_data({
			"is_steam_game": is_steam_campaign,
			"label": campaign_data.label,
			"host": enet_host,
			"username": presence.username,
			"password": enet_password,
		}):
			Debug.print_error_message("Failed to create Server file")
			
	# purge resources
	var remote_resource_timestamps: Dictionary = campaign_data.get("resources", {})
	for resource: CampaignResource in Game.resources.values():
		if resource.path not in remote_resource_timestamps:
			resource.remove()
			continue
		if resource.timestamp < remote_resource_timestamps[resource.path]:
			resource.update()

	# init jukebox
	var jukebox_data: Dictionary = campaign_data.get("jukebox", {})
	var music_data: Dictionary = jukebox_data.get("music", {})
	for music_path in music_data:
		var sound_data: Dictionary = music_data[music_path]
		var sound := Game.manager.get_resource(CampaignResource.Type.SOUND, sound_data.resource)
		if not sound.resource_loaded:
			await sound.loaded
			
		Game.ui.tab_jukebox.add_sound(sound, sound_data.get("position", 0.0))
		
	if jukebox_data.get("muted", false):
		Game.ui.tab_jukebox.audio.volume_db = linear_to_db(0)
	
	# init state
	Game.flow.change_flow_state(campaign_data.state)
	
	# init map
	request_map.rpc_id(1, campaign_data.players_map)


# player
@rpc("any_peer", "reliable")
func request_map_notification(map_slug: String):
	request_map.rpc_id(1, map_slug)


# master
@rpc("any_peer", "reliable")
func request_map(map_slug: String):
	Debug.print_info_message("Requested map %s" % map_slug)
	var id := multiplayer.get_remote_sender_id()
	var map: Map = Game.maps.get(map_slug)
	var map_data: Dictionary = map.json()
	
	load_map.rpc_id(id, map_slug, map_data)


# player
@rpc("any_peer", "reliable")
func load_map(map_slug: String, map_data: Dictionary):
	Debug.print_info_message("Loading map %s" % map_slug)
	
	if not Game.ui.selected_map or map_slug != Game.ui.selected_map.slug:
		for scene_tab in Game.ui.scene_tabs.get_children():
			scene_tab.remove()
		
		var tab_scene: TabScene = Game.manager.TAB_SCENE.instantiate().init(map_slug, map_data)
		Game.manager.map_loaded.emit(tab_scene.map.slug)
		tab_scene.map.is_master_view = false
		tab_scene.map.current_ambient_light = tab_scene.map.ambient_light
		tab_scene.map.current_ambient_color = tab_scene.map.ambient_color
	
	request_player.rpc_id(1, presence.slug)


# master
@rpc("any_peer", "reliable")
func request_player(_player_slug: String):
	Debug.print_info_message("Requested player %s" % _player_slug)
	var player_id := multiplayer.get_remote_sender_id() 
	var player_data := Game.campaign.get_player_data(_player_slug)
	var player_state: FlowController.State = \
			Game.ui.tab_players.get_player_item_data(_player_slug).get("state", 0)
	if not player_state:
		player_state = Game.flow.state
	load_player.rpc_id(player_id, _player_slug, player_data, player_state)


# player
@rpc("any_peer", "reliable")
func load_player(_player_slug: String, player_data: Dictionary, player_state: FlowController.State):
	Debug.print_info_message("Loading player %s" % _player_slug)
	Game.player = Player.new(_player_slug, player_data)
	
	Game.flow.change_flow_state(player_state)
	
	for element in Game.ui.selected_map.selected_level.elements:
		if element is Entity:
			element.is_selectable = false
			element.eye.visible = false
	
	for element_id in Game.player.elements:
		var entity: Entity = Game.ui.selected_map.selected_level.elements.get(element_id)
		if entity:
			var element_control_data: Dictionary = Game.player.elements[element_id]
			entity.is_selectable = element_control_data.get("movement", false)
			entity.eye.visible = element_control_data.get("senses", false)
			Game.ui.selected_map.camera.position_2d = entity.position_2d
			Debug.print_info_message("Player \"%s\" got control of \"%s\"" % [presence.username, element_id])


# player
@rpc("any_peer", "reliable")
func resource_change_notification(resource_path: String, timestamp := -1):
	var resource: CampaignResource = Game.resources[resource_path]
	resource.resource_loaded = false
	request_resource.rpc_id(1, resource_path, timestamp)


# master
@rpc("any_peer", "reliable")
func request_resource(resource_path: String, timestamp := -1):
	Debug.print_info_message("Requested resource %s" % resource_path)
	var id := multiplayer.get_remote_sender_id()
	var resource: CampaignResource = Game.resources.get(resource_path)
	
	# if master has not the file
	if not resource:
		Debug.print_info_message("Requested resource %s not exist" % resource_path)
		removed_resource.rpc_id(id, resource_path)
	
	# if player has the file and it is updated
	elif resource.timestamp <= timestamp:
		comfirm_resource.rpc_id(id, resource_path, resource.json())
	
	# if player has not the file
	else:
		send_resource(id, resource)
	
	
# player
@rpc("any_peer", "reliable")
func removed_resource(resource_path: String):
	Debug.print_info_message("Removed resource %s" % resource_path)
	
	var resource: CampaignResource = Game.resources[resource_path]
	resource.resource_loaded = true
	#Game.manager.set_resource(resource.resource_type, resource_path, {})

# player
@rpc("any_peer", "reliable")
func comfirm_resource(resource_path: String, resource_data: Dictionary):
	Debug.print_info_message("Comfirmed resource %s" % resource_path)
	
	var resource_abspath := Game.campaign.get_resource_abspath(resource_path)
	if not FileAccess.file_exists(resource_abspath):
		Debug.print_error_message("Resource %s not present" % resource_path)
	
	var resource: CampaignResource = Game.resources[resource_path]
	resource.resource_loaded = true
	Game.manager.set_resource(resource.resource_type, resource_path, resource_data)


#region tranfers

# master
func send_resource(id: int, resource: CampaignResource):
	Debug.print_info_message("sending resource %s to %s" % [resource.path, id])
	
	while is_transferring:
		await transfer_completed
	is_transferring = true
	
	var bytes = resource.bytes
	if not bytes:
		Debug.print_error_message("Requested resource %s not found" % resource.path)
		is_transferring = false
		transfer_completed.emit()
		return
		
	var resource_size = bytes.size()
	new_transfer.rpc_id(id, resource.resource_type, resource.path, resource.json(), resource_size)
	await new_transfer_ready_signal
	
	Debug.print_info_message("Resource tranfer starts: %s (%s b)" % [resource.path, resource_size])
	
	const CHUNK_SIZE := 1024 * 256
	var slices := ceili(float(resource_size) / CHUNK_SIZE)
	Debug.print_info_message("Resource divided into %s slices" % slices)
	for i in range(slices):
		var start_byte := i * CHUNK_SIZE
		var end_byte := start_byte + CHUNK_SIZE
		load_chunk.rpc_id(id, bytes.slice(start_byte, end_byte))
		await chunk_loaded_signal
	
	is_transferring = false
	Debug.print_info_message("Transfer complete: %s" % resource.path)
	transfer_completed.emit()

signal transfer_completed
var is_transferring := false
var transferred_bytes := PackedByteArray()
var transferred_type := ""
var transferred_path := ""
var transferred_data := {}
var transferred_size := 0

# player
@rpc("any_peer", "reliable")
func new_transfer(resource_type: String, resource_path: String, resource_data: Dictionary, resource_size: int):
	Debug.print_info_message("Resource tranfer queued: %s (%s b)" % [resource_path, resource_size])
	
	while is_transferring:
		await transfer_completed
	is_transferring = true
	
	var resource_abspath := Game.campaign.get_resource_abspath(resource_path)
	Utils.remove_file(resource_abspath)  # remove outdated version
	
	Debug.print_info_message("Resource tranfer starts: %s (%s b)" % [resource_path, resource_size])
	transferred_bytes.clear()
	transferred_type = resource_type
	transferred_path = resource_path
	transferred_data = resource_data
	transferred_size = resource_size
	new_transfer_ready.rpc_id(1)

# master
@rpc("any_peer", "reliable")
func new_transfer_ready():
	new_transfer_ready_signal.emit()

signal new_transfer_ready_signal

# player
@rpc("any_peer", "reliable")
func load_chunk(bytes_slice: PackedByteArray):
	chunk_loaded.rpc_id(1)
	
	transferred_bytes.append_array(bytes_slice)
	
	# check if it is the last chunk
	if transferred_size == transferred_bytes.size():
		finish_transfer()

# player
func finish_transfer():
	Debug.print_info_message("Received the entire resource %s" % transferred_path)
	var resource_abspath := Game.campaign.get_resource_abspath(transferred_path)
	
	Utils.make_dirs(resource_abspath.get_base_dir())
	
	var resource_file := FileAccess.open(resource_abspath, FileAccess.WRITE)
	resource_file.store_buffer(transferred_bytes)
	resource_file.close()
	
	if not FileAccess.file_exists(resource_abspath):
		Debug.print_error_message("Resource %s not stored" % transferred_path)
		
	var resource: CampaignResource = Game.resources.get(transferred_path)
	if not resource:
		resource = CampaignResource.new(transferred_type, transferred_path, transferred_data)
		Game.resources[transferred_path] = resource
	else:
		Game.manager.set_resource(transferred_type, transferred_path, transferred_data)
	
	resource.resource_loaded = true
	is_transferring = false
	Debug.print_info_message("Transfer complete: %s" % transferred_path)
	transfer_completed.emit()

# master
@rpc("any_peer", "reliable")
func chunk_loaded():
	chunk_loaded_signal.emit()

signal chunk_loaded_signal


#endregion
