class_name Loader
extends Node


@onready var map := $".." as Map


func load_donjon_json_file(json_file_path):
	print("Loading donjon map: " + json_file_path)

	var map_data := Utils.load_json(json_file_path)
	if not map_data:
		return
		
	map.label = map_data["settings"]["name"]
	var level := Game.level_scene.instantiate().init(map) as Level
	map.selected_level = level
	var viewport_3d := level.viewport_3d
	var floor_2d := viewport_3d.floor_2d
	var tile_map := floor_2d.tile_map
	
	var cells_data = map_data["cells"]
	
	var len_x = cells_data[0].size()
	var len_z = cells_data.size()
	level.rect = Rect2i(0, 0, len_x, len_z)
	
	#floors[0] = MRPAS.new(Vector2(len_x, len_z))
	seed(0)
	
	#var void_index : int = 18
	var void_index : int = 63
	#var ground_index : int = 6
	#var door_index : int = 2
	#var wall_index : int = 7
	
	#var void_index : int = 24
	var ground_index : int = 24
	var door_index : int = 2
	var wall_index : int = 1
	
	# ground
	for x in range(len_x):
		for z in range(len_z): 
			var donjon_code = cells_data[z][x]
			var cell_is_wall = int(donjon_code) in [0, 16]
			var cell_is_door = int(donjon_code) in [131076]
			
			var random_var : int = range(4).pick_random()
			if cell_is_wall:
				tile_map.set_cell(0, Vector2i(x, z), 0, Vector2i(random_var, void_index), 0)
			elif cell_is_door:
				tile_map.set_cell(0, Vector2i(x, z), 0, Vector2i(random_var, door_index), 0)
			else:
				tile_map.set_cell(0, Vector2i(x, z), 0, Vector2i(random_var, ground_index), 0)
	
	# horizontal walls
	for z in range(len_z):
		var wall : Wall = null
		var wall_last_point : WallPoint = null
		
		for x in range(1, len_x): 
			var donjon_code_down = cells_data[z][x]
			var donjon_code_up = cells_data[z - 1][x]
			var cell_is_wall_down = int(donjon_code_down) in [0, 16]
			var cell_is_wall_up = int(donjon_code_up) in [0, 16]
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
			var is_wall_left = cell_is_wall_right and not cell_is_wall_left
			var is_wall_right = cell_is_wall_left and not cell_is_wall_right
			
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
			var cell_is_wall = int(donjon_code) in [0, 16]
			var cell_is_door = int(donjon_code) in [131076]
			
			light_counter -= 1
			if light_counter < 0 and not cell_is_wall and not cell_is_door:
				var light_position := Vector2(x + 0.5, z + 0.5)
				var _light : Light = Game.light_scene.instantiate().init(level, light_position)
				light_counter = light_frecuency
	
	#map.ambient_light = 0.5
	map.ambient_light = 0
	
	# entities
	var entity_frecuency := 50
	var entity_counter := entity_frecuency
	for x in range(len_x): 
		for z in range(len_z):
			var donjon_code = cells_data[z][x]
			var cell_is_wall = int(donjon_code) in [0, 16]
			var cell_is_door = int(donjon_code) in [131076]
			
			entity_counter -= 1
			if entity_counter < 0 and not cell_is_wall and not cell_is_door:
				var entity_position := Vector2(x + 0.5, z + 0.5)
				var _entity : Entity = Game.entity_scene.instantiate().init(level, entity_position)
				entity_counter = entity_frecuency
	
	
#func _load_fried_json_file(json_file_path):
	#var serialized_map = Utils.loads_json(json_file_path)
	#deserialize(serialized_map)
