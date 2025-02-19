class_name Campaign
extends Resource


var is_master := false
var label := "Untitled"
var slug := "untitled"
var path := ""

var campaigns_path := "user://campaigns"
var servers_path := "user://servers"

var maps_path: String :
	get: return path.path_join("maps")

var maps: PackedStringArray : 
	get: return DirAccess.get_directories_at(maps_path)
		
var players_path: String :
	get: return path.path_join("players")

var players: PackedStringArray : 
	get: return DirAccess.get_directories_at(players_path)
		
var blueprints_path: String :
	get: return path.path_join("blueprints")
	
var resources_path: String :
	get: return path.path_join("resources")

var resources := {}


func _init(_is_master: bool, _slug: String, _data: Dictionary):
	is_master = _is_master
	slug = _slug
	label = _data.label
	if is_master:
		path = campaigns_path.path_join(slug)
		Utils.make_dirs(maps_path)
		Utils.make_dirs(players_path)
		Utils.make_dirs(blueprints_path)
		Utils.make_dirs(resources_path)
	else:
		path = servers_path.path_join(slug)
		Utils.make_dirs(resources_path)


func load_campaign_data() -> Dictionary:
	return Utils.load_json(campaigns_path.path_join(slug).path_join("campaign.json"))

func save_campaign_data() -> Error:
	return Utils.dump_json(campaigns_path.path_join(slug).path_join("campaign.json"), json(), 2)

func load_server_data() -> Dictionary:
	return Utils.load_json(servers_path.path_join(slug).path_join("server.json"))

func save_server_data(server_data) -> Error:
	return Utils.dump_json(servers_path.path_join(slug).path_join("server.json"), server_data, 2)

func get_map_path(map_slug: String) -> String:
	return maps_path.path_join(map_slug)

func get_map_data(map_slug: String) -> Dictionary:
	return Utils.load_json(get_map_path(map_slug).path_join("map.json"))

func set_map_data(map_slug: String, map_data: Dictionary) -> Error:
	return Utils.dump_json(get_map_path(map_slug).path_join("map.json"), map_data)

func get_player_path(player_slug: String) -> String:
	return players_path.path_join(player_slug)

func get_player_data(player_slug: String, not_exist_ok := false) -> Dictionary:
	return Utils.load_json(get_player_path(player_slug).path_join("player.json"), not_exist_ok)

func set_player_data(player_slug: String, player_data: Dictionary) -> Error:
	return Utils.dump_json(get_player_path(player_slug).path_join("player.json"), player_data, 2)


func get_blueprint_abspath(blueprint_path: String) -> String:
	return blueprints_path.path_join(blueprint_path)

func blueprint_exists(blueprint_path: String) -> bool:
	return FileAccess.file_exists(get_blueprint_abspath(blueprint_path).path_join("blueprint.json"))

func get_blueprint_data(blueprint_path: String) -> Dictionary:
	return Utils.load_json(get_blueprint_abspath(blueprint_path).path_join("blueprint.json"), true)

func set_blueprint_data(blueprint_path: String, blueprint_data: Dictionary) -> Error:
	return Utils.dump_json(get_blueprint_abspath(blueprint_path).path_join("blueprint.json"), blueprint_data, 2)
	

func get_resource_abspath(resource_file_path: String) -> String:
	return resources_path.path_join(resource_file_path)

func resource_file_exists(resource_file_path: String) -> bool:
	return FileAccess.file_exists(get_resource_abspath(resource_file_path))

func get_resource_data(resource_file_path: String) -> Dictionary:
	return Utils.load_json(get_resource_abspath(resource_file_path) + ".json", true)

func set_resource_data(resource_file_path: String, resource_data: Dictionary) -> Error:
	var resource_abspath := get_resource_abspath(resource_file_path)
	return Utils.dump_json(resource_abspath + ".json", resource_data, 2)


func json() -> Dictionary :
	return {
		"label": label,
		"master": Game.master.json(),
		"state": Game.flow.state,
		"players": Game.ui.tab_players.get_data(),
		"selected_map": Game.ui.selected_map.slug,
		"players_map": Game.ui.tab_world.players_map,
		"opened_maps": Game.maps.keys(),
		"jukebox": Game.ui.tab_jukebox.get_data(),
		"resources": resources,
	}
