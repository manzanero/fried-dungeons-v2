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
		
		
var entities_path: String :
	get:
		return "user://campaigns/%s/entities" % slug


var entities: Array[String] : 
	get:
		check()
		var _entities: Array[String] = []
		var dirs := DirAccess.get_directories_at(entities_path)
		for dir in dirs:
			_entities.append(dir)
		return _entities
		

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
