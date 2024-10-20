class_name Campaign
extends Resource


var is_master := false

var label := "Untitled"
var imports := {}
#var jukebox_sounds := []


var slug: String :
	get: return Utils.slugify(label)

var campaign_path := ""

var campaign_data: Dictionary :
	get: return Utils.load_json(campaign_path.path_join("campaign.json"))

var maps_path: String :
	get: return campaign_path.path_join("maps")

var maps: Array[String] : 
	get:
		var _maps: Array[String] = []
		var _maps_path := maps_path
		var dirs := DirAccess.get_directories_at(maps_path)
		for dir in dirs:
			_maps.append(dir)
		return _maps
		
var players_path: String :
	get: return campaign_path.path_join("players")

var players: Array[String] : 
	get:
		var _players: Array[String] = []
		var dirs := DirAccess.get_directories_at(players_path)
		for dir in dirs:
			_players.append(dir)
		return _players

var resources_path: String :
	get: return campaign_path.path_join("resources")

var resources: Array[String] : 
	get:
		var _elements: Array[String] = []
		var dirs := DirAccess.get_directories_at(resources_path)
		for dir in dirs:
			_elements.append(dir)
		return _elements


func json() -> Dictionary :
	return {
		"label": label,
		"state": Game.flow.state,
		"imports": imports,
		"jukebox": Game.ui.tab_jukebox.get_data(),
		"opened_maps": Game.maps.keys(),
		"selected_map": Game.ui.selected_map.slug,
		"players_map": Game.ui.tab_world.players_map,
	}


func _init(_is_master := false, _label := "", _imports := {}):
	is_master = _is_master
	label = _label
	imports = _imports
	
	if is_master:
		campaign_path = "user://campaigns".path_join(slug)
	else:
		campaign_path = "user://servers".path_join(slug)
		

func get_map_path(map_slug: String) -> String:
	return maps_path.path_join(map_slug)

func get_map_data(map_slug: String) -> Dictionary:
	return Utils.load_json(get_map_path(map_slug).path_join("map.json"))

func get_player_path(player_slug: String) -> String:
	return players_path.path_join(player_slug)

func get_player_data(player_slug: String) -> Dictionary:
	return Utils.load_json(get_player_path(player_slug).path_join("player.json"))

func set_player(player_slug: String, player_data: Dictionary) -> void:
	return Utils.dump_json(get_player_path(player_slug).path_join("player.json"), player_data)
