class_name Campaign
extends Resource


@export var label := "Untitled"
@export var is_master := true


var slug: String :
	get:
		return Utils.slugify(label)


var campaign_path: String :
	get:
		return "user://campaigns/%s" % slug


var maps_path: String :
	get:
		return "user://campaigns/%s/maps" % slug


var maps: Array[String] : 
	get:
		check()
		var _maps: Array[String] = []
		var dirs := DirAccess.get_directories_at(maps_path)
		for dir in dirs:
			_maps.append(dir)
		return _maps
		
		
var players_path: String :
	get:
		return "user://campaigns/%s/players" % slug


var players: Array[String] : 
	get:
		check()
		var _players: Array[String] = []
		var dirs := DirAccess.get_directories_at(players_path)
		for dir in dirs:
			_players.append(dir)
		return _players
		
		
var elements_path: String :
	get:
		return "user://campaigns/%s/elements" % slug


var elements: Array[String] : 
	get:
		check()
		var _elements: Array[String] = []
		var dirs := DirAccess.get_directories_at(elements_path)
		for dir in dirs:
			_elements.append(dir)
		return _elements
		

var json: Dictionary :
	get:
		return {
			"label": label,
		}


func init(_label, _is_master := true):
	label = _label
	is_master = _is_master
	return self


func get_map(map_slug: String) -> Dictionary:
	return Utils.load_json("%s/%s/map.json" % [maps_path, map_slug])


func get_player(player_slug: String) -> Dictionary:
	return Utils.load_json("%s/%s/player.json" % [players_path, player_slug])


func set_player(player_slug: String, player_data: Dictionary) -> void:
	return Utils.dump_json("%s/%s/player.json" % [players_path, player_slug], player_data)
	

func save() -> void:
	check()
	Utils.dump_json("%s/campaign.json" % [campaign_path, slug], json)
		

func check() -> void:
	if not DirAccess.dir_exists_absolute(campaign_path):
		DirAccess.make_dir_recursive_absolute(campaign_path)
	if not DirAccess.dir_exists_absolute(maps_path):
		DirAccess.make_dir_recursive_absolute(maps_path)
	if not DirAccess.dir_exists_absolute(players_path):
		DirAccess.make_dir_recursive_absolute(players_path)
	if not DirAccess.dir_exists_absolute(elements_path):
		DirAccess.make_dir_recursive_absolute(players_path)
