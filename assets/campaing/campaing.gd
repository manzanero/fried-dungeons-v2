class_name Campaign
extends Resource


var is_master := false
var label := "Untitled"
var slug := "untitled"
var path := ""

var maps_path: String :
	get: return path.path_join("maps")

var maps: PackedStringArray : 
	get: return DirAccess.get_directories_at(maps_path)
		
var players_path: String :
	get: return path.path_join("players")

var players: PackedStringArray : 
	get: return DirAccess.get_directories_at(players_path)

var resources_path: String :
	get: return path.path_join("resources")

var resources := {}


func _init(_is_master: bool, _slug: String, _label: String):
	is_master = _is_master
	slug = _slug
	label = _label
	var root_folder := "user://campaigns" if is_master else "user://servers"
	path = root_folder.path_join(slug)


func load_campaign_data() -> Dictionary:
	return Utils.load_json(path.path_join("campaign.json"))

func save_campaign_data() -> Error:
	return Utils.dump_json(path.path_join("campaign.json"), json(), 2)

func get_map_path(map_slug: String) -> String:
	return maps_path.path_join(map_slug)

func get_map_data(map_slug: String) -> Dictionary:
	return Utils.load_json(get_map_path(map_slug).path_join("map.json"))

func set_map_data(map_slug: String, map_data: Dictionary) -> Error:
	return Utils.dump_json(get_map_path(map_slug).path_join("map.json"), map_data)

func get_player_path(player_slug: String) -> String:
	return players_path.path_join(player_slug)

func get_player_data(player_slug: String) -> Dictionary:
	return Utils.load_json(get_player_path(player_slug).path_join("player.json"))

func set_player(player_slug: String, player_data: Dictionary) -> Error:
	return Utils.dump_json(get_player_path(player_slug).path_join("player.json"), player_data, 2)

func get_resource_abspath(_resource_path: String) -> String:
	return resources_path.path_join(_resource_path)

func get_resource_data(_resource_path: String) -> Dictionary:
	var resource_abspath := get_resource_abspath(_resource_path)
	return Utils.load_json(resource_abspath + ".json", true)

func set_resource_data(_resource_path: String, resource_data: Dictionary) -> Error:
	var resource_abspath := get_resource_abspath(_resource_path)
	return Utils.dump_json(resource_abspath + ".json", resource_data, 2)


func json() -> Dictionary :
	return {
		#"slug": slug,
		"label": label,
		"state": Game.flow.state,
		"selected_map": Game.ui.selected_map.slug,
		"players_map": Game.ui.tab_world.players_map,
		"opened_maps": Game.maps.keys(),
		"jukebox": Game.ui.tab_jukebox.get_data(),
		"resources": resources,
	}
