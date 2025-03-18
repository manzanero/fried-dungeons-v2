class_name Loader
extends Node


@onready var map: Map = $".."


#region donjon

func load_donjon_json_file(json_file_path):
	seed(Game.world_seed)
	Debug.print_message(Debug.INFO, "Loading donjon map: " + json_file_path)

	var map_data := Utils.load_json(json_file_path)
	if not map_data:
		return
		
	map.label = map_data["settings"]["name"]
	map.slug = Utils.slugify(map.label)
	var level := Level.SCENE.instantiate().init(map) as Level
	map.selected_level = level
	var viewport_3d := level.viewport_3d
	var floor_2d := viewport_3d.floor_2d
	var tile_map := floor_2d.tile_map
	
	var cells_data = map_data["cells"]
	
	var len_x = cells_data[0].size()
	var len_z = cells_data.size()
	level.rect = Rect2i(0, 0, len_x, len_z)
	
	var void_index : int = 4
	var ground_index : int = 2
	var door_index : int = 16
	var wall_index : int = 5
	var portcullis_index : int = 7
	
	# ground
	for x in range(len_x):
		for z in range(len_z): 
			var donjon_code : float = cells_data[z][x]
			var cell_is_wall := int(donjon_code) in [0, 16]
			
			var random_var : int = range(4).pick_random()
			var tile := Vector2i(x, z)
			if cell_is_wall:
				level.cells[tile] = Level.Cell.new(void_index, random_var)
				tile_map.set_cell(0, tile, 0, Vector2i(random_var, void_index), 0)
			else:
				level.cells[tile] = Level.Cell.new(ground_index, random_var)
				tile_map.set_cell(0, tile, 0, Vector2i(random_var, ground_index), 0)
	
	# horizontal walls
	for z in range(len_z):
		var wall: Wall = null
		var wall_last_point: WallPoint = null
		
		for x in range(1, len_x): 
			var donjon_code_down : float = cells_data[z][x]
			var donjon_code_up : float = cells_data[z - 1][x]
			var cell_is_wall_down := int(donjon_code_down) in [0, 16]
			var cell_is_wall_up := int(donjon_code_up) in [0, 16]
			var is_wall_down = cell_is_wall_up and not cell_is_wall_down
			var is_wall_up = cell_is_wall_down and not cell_is_wall_up
			
			var random_var : int = range(1000).pick_random()
			if is_wall_down:
				if wall_last_point:
					wall.set_point(wall_last_point, Vector2(x + 1, z))
				else:
					wall = Game.wall_scene.instantiate().init(level, wall_index, random_var)
					wall.add_point(Vector2(x, z))
					wall_last_point = wall.add_point(Vector2(x + 1, z))
			
			elif is_wall_up:
				if wall_last_point:
					wall.set_point(wall_last_point, Vector2(x + 1, z))
				else:
					wall = Game.wall_scene.instantiate().init(level, wall_index, random_var)
					wall_last_point = wall.add_point(Vector2(x + 1, z))
					wall.add_point(Vector2(x, z))
					
			else:
				wall_last_point = null
	
	# vertical walls
	for x in range(len_x):
		var wall : Wall = null
		var wall_last_point : WallPoint = null
		
		for z in range(1, len_z): 
			var donjon_code_left : float = cells_data[z][x - 1]
			var donjon_code_right : float = cells_data[z][x]
			var cell_is_wall_left := int(donjon_code_left) in [0, 16]
			var cell_is_wall_right := int(donjon_code_right) in [0, 16]
			var is_wall_left := cell_is_wall_right and not cell_is_wall_left
			var is_wall_right := cell_is_wall_left and not cell_is_wall_right

			var random_var : int = range(1000).pick_random()
			if is_wall_left:
				if wall_last_point:
					wall.set_point(wall_last_point, Vector2(x, z + 1))
				else:
					wall = Game.wall_scene.instantiate().init(level, wall_index, random_var)
					wall.add_point(Vector2(x, z))
					wall_last_point = wall.add_point(Vector2(x, z + 1))

			elif is_wall_right:
				if wall_last_point:
					wall.set_point(wall_last_point, Vector2(x, z + 1))
				else:
					wall = Game.wall_scene.instantiate().init(level, wall_index, random_var)
					wall_last_point = wall.add_point(Vector2(x, z + 1))
					wall.add_point(Vector2(x, z))

			else:
				wall_last_point = null
	
	# lights
	var light_frecuency := 30
	var light_counter := light_frecuency
	for x in range(len_x):
		for z in range(len_z):
			var donjon_code = cells_data[z][x]
			var cell_is_wall := int(donjon_code) in [0, 16]
			var cell_is_door := int(donjon_code) in [131076]
			
			light_counter -= 1
			if light_counter < 0 and not cell_is_wall and not cell_is_door:
				var light_position := Vector2(x + 0.5, z + 0.5)
				var _light : Light = Game.light_scene.instantiate().init(level, light_position)
				light_counter = light_frecuency
	
	# entities
	var entity_frecuency := 50
	var eye_entity_frecuency := 10
	var entity_counter := entity_frecuency
	var eye_entity_counter := eye_entity_frecuency
	for x in range(len_x): 
		for z in range(len_z):
			var donjon_code = cells_data[z][x]
			var cell_is_wall = int(donjon_code) in [0, 16]
			var cell_is_door = int(donjon_code) in [131076]
			
			entity_counter -= 1
			if entity_counter < 0 and not cell_is_wall and not cell_is_door:
				var entity_position := Vector2(x + 0.5, z + 0.5)
				var entity: Entity = Game.entity_scene.instantiate().init(level, 
						Utils.random_string(8, true), entity_position, {
					"color": Color.RED
				})
				entity_counter = entity_frecuency
				
				eye_entity_counter -= 1
				if eye_entity_counter < 0:
					eye_entity_counter = eye_entity_frecuency
					entity.eye.visible = true
	
	# doors
	for x in range(len_x):
		for z in range(len_z): 
			var donjon_code : float = cells_data[z][x]
			var donjon_code_down : float = cells_data[z - 1][x]
			var cell_is_door := int(donjon_code) in [131076]
			var cell_is_arch := int(donjon_code) in [65540]
			var cell_is_portcullis := int(donjon_code) in [2097156]
			var cell_down_is_wall := int(donjon_code_down) in [0, 16]
			
			if cell_is_door:
				if cell_down_is_wall:
					_create_north_door(level, Vector2(x, z), door_index, wall_index)
				else:
					_create_west_door(level, Vector2(x, z), door_index, wall_index)
			elif cell_is_arch:
				if cell_down_is_wall:
					_create_north_arch(level, Vector2(x, z), wall_index)
				else:
					_create_west_arch(level, Vector2(x, z), wall_index)
			elif cell_is_portcullis:
				if cell_down_is_wall:
					_create_north_portcullis(level, Vector2(x, z), portcullis_index)
				else:
					_create_west_portcullis(level, Vector2(x, z), portcullis_index)


func _get_global_grid_points(offset: Vector2, local_grid_points: PackedVector2Array) -> PackedVector2Array:
	const U = 1.0 / 16.0
	var global_points : PackedVector2Array = []
	for point in local_grid_points:
		global_points.append(offset + U * point)
	return global_points
	

const DOOR_WALLS: Array[Array] = [
	[[6, 0], [6, 4], [10, 4], [10, 0]],
	[[10, 16], [10, 12], [6, 12], [6, 16]],
	[[7, 4], [7, 12]],
	[[9, 12], [9, 4]],
]

const ARCH_WALLS: Array[Array] = [
	[[6, 0], [6, 4], [10, 4], [10, 0]],
	[[10, 16], [10, 12], [6, 12], [6, 16]],
]

#const PORTCULLIS_WALLS: Array[Array] = [
	#[[8, 0], [8, 16]],
	#[[10, 16], [10, 0]],
#]

const PORTCULLIS_WALLS: Array[Array] = [
	[[8, 0], [8, 16]],
]

func _create_north_door(level, offset, door_index, wall_index):
	var walls_points := Utils.aaa2_to_apv2(DOOR_WALLS).map(func (x): return _get_global_grid_points(offset, x))
	Game.wall_scene.instantiate().init(level, wall_index).add_points(walls_points[0])
	Game.wall_scene.instantiate().init(level, wall_index).add_points(walls_points[1])
	Game.wall_scene.instantiate().init(level, door_index).add_points(walls_points[2])
	Game.wall_scene.instantiate().init(level, door_index).add_points(walls_points[3])

func _create_west_door(level, offset, door_index, wall_index):
	var walls_points := Utils.aaa2_to_atpv2(DOOR_WALLS).map(func (x): return _get_global_grid_points(offset, x))
	Game.wall_scene.instantiate().init(level, wall_index).add_points(walls_points[0])
	Game.wall_scene.instantiate().init(level, wall_index).add_points(walls_points[1])
	Game.wall_scene.instantiate().init(level, door_index).add_points(walls_points[2])
	Game.wall_scene.instantiate().init(level, door_index).add_points(walls_points[3])

func _create_north_arch(level, offset, wall_index):
	var walls_points := Utils.aaa2_to_apv2(ARCH_WALLS).map(func (x): return _get_global_grid_points(offset, x))
	Game.wall_scene.instantiate().init(level, wall_index).add_points(walls_points[0])
	Game.wall_scene.instantiate().init(level, wall_index).add_points(walls_points[1])

func _create_west_arch(level, offset, wall_index):
	var walls_points := Utils.aaa2_to_atpv2(ARCH_WALLS).map(func (x): return _get_global_grid_points(offset, x))
	Game.wall_scene.instantiate().init(level, wall_index).add_points(walls_points[0])
	Game.wall_scene.instantiate().init(level, wall_index).add_points(walls_points[1])

func _create_north_portcullis(level, offset, portcullis_index):
	var walls_points := Utils.aaa2_to_apv2(PORTCULLIS_WALLS).map(func (x): return _get_global_grid_points(offset, x))
	Game.wall_scene.instantiate().init(level, portcullis_index, 0, 1, true).add_points(walls_points[0])
	#Game.wall_scene.instantiate().init(level, portcullis_index, 1, true).add_points(walls_points[1])

func _create_west_portcullis(level, offset, portcullis_index):
	var walls_points := Utils.aaa2_to_atpv2(PORTCULLIS_WALLS).map(func (x): return _get_global_grid_points(offset, x))
	Game.wall_scene.instantiate().init(level, portcullis_index, 0, 1, true).add_points(walls_points[0])
	#Game.wall_scene.instantiate().init(level, portcullis_index, 1, true).add_points(walls_points[1])

#endregion


func load_map(map_data: Dictionary):
	seed(Game.world_seed)
	Debug.print_info_message("Loading map: " + map_data.label)
	
	map.label = map_data.label
	map.description = map_data.get_or_add("description", "")
	
	if map_data.has("settings"):
		var atlas_texture_path: String = map_data.settings.get("atlas_texture", "")
		map.atlas_texture_resource = Game.manager.get_resource(CampaignResource.Type.TEXTURE, atlas_texture_path)
		
		map.ambient_light = map_data.settings.get("ambient_light", 0)
		map.ambient_color = Utils.html_color_to_color(map_data.settings.get("ambient_color", "ffffffff"))
		map.master_ambient_light = map_data.settings.get("master_ambient_light", 0.25)
		map.master_ambient_color = Utils.html_color_to_color(map_data.settings.get("master_ambient_color", "ffffffff"))
		map.override_ambient_light = map_data.settings.get("override_ambient_light", true)
		map.override_ambient_color = map_data.settings.get("override_ambient_color", false)
		
		map.current_ambient_light = map.ambient_light
		map.current_ambient_color = map.ambient_color
		
		if Game.campaign.is_master:
			if map.override_ambient_light:
				map.current_ambient_light = map.master_ambient_light
			if map.override_ambient_color:
				map.current_ambient_color = map.master_ambient_color
		
		map.visibility = map_data.settings.get("visibility", 1.0)

	
	# It is an empty map
	if not map_data.has("levels"):
		var level: Level = Level.SCENE.instantiate().init(map, 0)
		level.rect = Rect2i(0, 0, 1, 1)
		
		var viewport_3d := level.viewport_3d
		var floor_2d := viewport_3d.floor_2d
		var tile_map := floor_2d.tile_map
		
		var tile := Vector2i(0, 0)
		var tile_data := {"i": 1, "f": 0}
		level.cells[tile] = Level.Cell.new(tile_data.i, tile_data.f)
		tile_map.set_cell(0, tile, 0, Vector2i(tile_data.f, tile_data.i), 0)
		var properties := {}
		if Game.campaign.resource_file_exists("heroes.png"):
			properties = {"body_texture": "heroes.png"}
		map.instancer.create_entity(level, Utils.random_string(8, true), Vector2(0.5, 0.5), properties)
		map.instancer.create_light(level, Utils.random_string(8, true), Vector2(0.5, 0.5))
		
	else:
		
		for level_index in map_data.levels:
			var level_data: Dictionary = map_data.levels[level_index]
			var index := int(level_index)
			var level: Level = Level.SCENE.instantiate().init(map, index)
			
			var viewport_3d := level.viewport_3d
			var floor_2d := viewport_3d.floor_2d
			var tile_map := floor_2d.tile_map
			var tiles_data = level_data.get("tiles", [])
			var rect = level_data.get("rect", {})
			var rect_position = rect.get("position", [0, 0])
			var rect_size = rect.get("size", [0, 0])
			var pos_x = rect_position[0]
			var pos_z = rect_position[1]
			var len_x = rect_size[0]
			var len_z = rect_size[1]
			level.rect = Rect2i(pos_x, pos_z, len_x, len_z)
		
			# ground
			for x in range(len_x):
				for z in range(len_z): 
					var tile_data = tiles_data[z][x]
					if not tile_data:
						continue
						
					var tile := Vector2i(x + pos_x, z + pos_z)
					level.cells[tile] = Level.Cell.new(tile_data.i, tile_data.f)
					tile_map.set_cell(0, tile, 0, Vector2i(tile_data.f, tile_data.i), 0)
					
			# walls
			for wall_data in level_data.get("walls", []):
				var id: String = wall_data.get("id", Utils.random_string(8, true))
				var points_position_2d := Utils.aa2_to_pv2(wall_data.p)
				map.instancer.create_wall(
						level, id, points_position_2d, wall_data.i, wall_data.s,
						wall_data.get("l", 1), wall_data.get("2", false), wall_data.get("c", false))
					
			# elements
			for element_data in level_data.get("elements", []):
				if not element_data:
					continue
				
				var rotation_y: float = element_data.get("rotation", 0.0)
				var flipped: bool = element_data.get("flipped", false)
				var is_favourite: bool = element_data.get("favourite", false)
				var raw_properties: Dictionary = element_data.get("properties", {})
				var blueprint_id: String = raw_properties.get("blueprint", "")
				var properties: Dictionary
				
				if raw_properties.label == "Marinero":
					pass
					
				if blueprint_id:
					var blueprint: CampaignBlueprint = Game.blueprints.get(blueprint_id)
					if blueprint:
						properties = blueprint.properties.duplicate()
						properties["label"] = raw_properties["label"]
						properties["blueprint"] = blueprint
				if not properties:
					match element_data.type:
						"light": properties = Light.parse_raw_property_values(raw_properties)
						"entity": properties = Entity.parse_raw_property_values(raw_properties)
						"prop": properties = Prop.parse_raw_property_values(raw_properties)
						_: properties = {}
				map.instancer.create_element(element_data.type, level, element_data.id, 
						Utils.a2_to_v2(element_data.position), properties, rotation_y, flipped, false, is_favourite)
	
	map.selected_level = map.levels_parent.get_children()[0]
