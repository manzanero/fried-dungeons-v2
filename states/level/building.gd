class_name LevelBuildingState
extends LevelBaseState


enum {
	ONE_SIDED, TWO_SIDED, ROOM, OBSTACLE,
	MOVE, CUT, CHANGE, FLIP, PAINT_WALL,
	PAINT_TILE, PAINT_RECT,
	NEW_ENTITY, NEW_LIGHT, NEW_SHAPE,
}


var mode: int
var material_index_selected: int :
	get: return Game.ui.tab_builder.material_index_selected

var st := SurfaceTool.new()

var _click_origin_position := Game.NULL_POSITION_2D
var _click_origin_tile := Game.NULL_TILE
var _is_rect_being_builded := false
var _wall_being_builded: Wall
var _previous_rotation: float
var _previous_properties := {}
var _wall_hovered: Wall


var _is_something_being_builded: bool :
	get: return _is_rect_being_builded or _wall_being_builded


func _enter_state(previous_state: String) -> void:
	super._enter_state(previous_state)
	Game.ui.build_border.visible = true
	selector.grid.visible = true
	selector.column.visible = true
	selector.position_2d = Game.NULL_POSITION_2D
	
	if mode in [MOVE, NEW_ENTITY, NEW_LIGHT, NEW_SHAPE, PAINT_TILE, PAINT_RECT]:
		selector.column.visible = false
	
	if mode in [CHANGE, FLIP, PAINT_WALL]:
		selector.grid.visible = false



func _exit_state(next_state: String) -> void:
	super._exit_state(next_state)
	Game.ui.build_border.visible = false
	selector.wall.mesh = null
	_is_rect_being_builded = false
	_wall_being_builded = null
	_previous_properties = {}
	_previous_rotation = 0.0
	if is_instance_valid(level.preview_element):
		level.preview_element.remove()


func _physics_process_state(_delta: float) -> String:
	if level != Game.ui.selected_map.selected_level:
		return ""
	
	process_ground_hitted()
	
	if Input.is_action_just_pressed("ui_cancel") and not _is_something_being_builded:
		Utils.reset_button_group(Game.ui.tab_builder.tile_button.button_group)
		Utils.reset_button_group(Game.ui.tab_instancer.entity_button.button_group)
		return "Idle"
	
	match mode:
		ONE_SIDED:
			process_change_grid()
			process_change_column()
			process_build_one_sided()
		TWO_SIDED:
			process_change_grid()
			process_change_column()
			process_build_two_sided()
		ROOM:
			process_change_grid()
			process_change_column()
			process_build_room()
		OBSTACLE:
			process_change_grid()
			process_change_column()
			process_build_room(true)
			
		MOVE:
			process_change_grid()
			process_wall_selection()
		CUT:
			process_change_grid()
			process_cutted_wall()
			process_cut_wall()
		CHANGE:
			process_hover_wall()
			process_change_wall()
		FLIP:
			process_hover_wall()
			process_flip_wall()
		PAINT_WALL:
			process_hover_wall()
			process_paint_wall()
			
		PAINT_TILE:
			process_change_grid()
			process_build_point()
		PAINT_RECT:
			process_change_grid()
			process_build_rect()
			
		NEW_ENTITY:
			process_change_grid()
			process_instance_entity()
		NEW_LIGHT:
			process_ceilling_hitted()
			process_change_grid()
			process_instance_light()
		NEW_SHAPE:
			process_change_grid()
			process_instance_shape()
			
	return ""


func process_build_point() -> void:
	if Input.is_action_just_pressed("left_click") and Game.ui.is_mouse_over_scene_tab:
		selector.area.visible = true
		
	if Input.is_action_pressed("left_click") and _click_origin_tile != level.tile_hovered and Game.ui.is_mouse_over_scene_tab:
		var tile := level.tile_hovered
		_click_origin_tile = tile
		selector.tiled_move_area_to(level.position_hovered, level.position_hovered)
		var random = range(8).pick_random()
		var tile_data := {"i": material_index_selected, "f": random}
		level.build_point(tile, tile_data)
		Game.server.rpcs.build_point.rpc(map.slug, level.index, tile, tile_data)
	
	if Input.is_action_just_released("left_click") and Game.ui.is_mouse_over_scene_tab:
		selector.area.visible = false
		_click_origin_tile = Game.NULL_TILE


func process_build_rect() -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		selector.area.visible = false
		_is_rect_being_builded = false
		
	if Input.is_action_just_pressed("left_click") and Game.ui.is_mouse_over_scene_tab:
		_click_origin_position = level.position_hovered
		_is_rect_being_builded = true
		selector.area.visible = true
		
	if Input.is_action_pressed("left_click") and Game.ui.is_mouse_over_scene_tab:
		selector.tiled_move_area_to(_click_origin_position, level.position_hovered)
		
	if Input.is_action_just_released("left_click") and _is_rect_being_builded:
		selector.area.visible = false
		_is_rect_being_builded = false
		
		if Game.ui.is_mouse_over_scene_tab:
			var init_x := int(_click_origin_position.floor().x)
			var init_y := int(_click_origin_position.floor().y)
			var end_x := level.tile_hovered.x
			var end_y := level.tile_hovered.y
			var dir_x := 1 if end_x > init_x else -1
			var dir_y := 1 if end_y > init_y else -1
			for x in range(init_x, end_x + dir_x, dir_x):
				for y in range(init_y, end_y + dir_y, dir_y):
					var random = range(8).pick_random()
					var tile := Vector2i(x, y)
					var tile_data := {"i": material_index_selected, "f": random}
					level.build_point(tile, tile_data)
					Game.server.rpcs.build_point.rpc(map.slug, level.index, tile, tile_data)


func process_hover_wall():
	if not Game.ui.is_mouse_over_scene_tab:
		return
		
	if is_instance_valid(_wall_hovered):
		_wall_hovered.line_renderer_3d.disabled = true
		
	var hit_info := Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, level_ray, Game.WALL_BITMASK)
	if hit_info:
		_wall_hovered = hit_info["collider"].get_parent()
		_wall_hovered.line_renderer_3d.disabled = false
		var wall_floor_position: Vector3 = hit_info["position"] * Vector3(1, 0, 1)
		selector.column.position = wall_floor_position
		selector.reset_vanish()
	else:
		_wall_hovered = null

		
func process_change_wall() -> void:
	if not Game.ui.is_mouse_over_scene_tab:
		return
		
	if not is_instance_valid(_wall_hovered):
		return
		
	if Input.is_action_just_pressed("left_click"):
		_wall_hovered.two_sided = not _wall_hovered.two_sided
			
		Game.server.rpcs.set_wall_properties.rpc(map.slug, level.index, _wall_hovered.id,
				_wall_hovered.material_index, _wall_hovered.material_seed, 
				_wall_hovered.material_layer, _wall_hovered.two_sided)

		
func process_flip_wall() -> void:
	if not Game.ui.is_mouse_over_scene_tab:
		return
		
	if not is_instance_valid(_wall_hovered):
		return
		
	if Input.is_action_just_pressed("left_click"):
		_wall_hovered.reverse()
			
		Game.server.rpcs.set_wall_properties.rpc(map.slug, level.index, _wall_hovered.id,
				_wall_hovered.material_index, _wall_hovered.material_seed, 
				_wall_hovered.material_layer, _wall_hovered.two_sided)


func process_paint_wall() -> void:
	if not Game.ui.is_mouse_over_scene_tab:
		return
		
	if not is_instance_valid(_wall_hovered):
		return
		
	if Input.is_action_just_pressed("left_click"):
		_wall_hovered.material_index = material_index_selected
			
		Game.server.rpcs.set_wall_properties.rpc(map.slug, level.index, _wall_hovered.id,
				_wall_hovered.material_index, _wall_hovered.material_seed, 
				_wall_hovered.material_layer, _wall_hovered.two_sided)


func process_build_one_sided() -> void:
	if not Game.ui.is_mouse_over_scene_tab:
		return
		
	if _wall_being_builded:
		process_build_one_sided_next_point()
		process_build_one_sided_new_point()
	else:
		process_build_one_sided_start()
		

func process_build_two_sided() -> void:
	if not Game.ui.is_mouse_over_scene_tab:
		return
		
	if _wall_being_builded:
		process_build_one_sided_next_point()
		process_build_one_sided_new_point()
	else:
		process_build_one_sided_start(true)
		

func process_build_one_sided_start(two_sided := false) -> void:
	if Input.is_action_just_pressed("left_click"):
		_click_origin_position = Utils.v3_to_v2(selector.column.position)
		_wall_being_builded = map.instancer.create_wall(level, Utils.random_string(8, true), 
				[_click_origin_position], material_index_selected, randi(), 1, two_sided)
		
		Game.server.rpcs.create_wall.rpc(map.slug, level.index, 
				_wall_being_builded.id,
				_wall_being_builded.points_position_2d, 
				_wall_being_builded.material_index, 
				_wall_being_builded.material_seed, 
				_wall_being_builded.material_layer, 
				_wall_being_builded.two_sided)
			
		Debug.print_info_message("Wall \"%s\" created" % _wall_being_builded.id)
		
		selector.wall.visible = true
		
		
func process_build_one_sided_next_point() -> void:
	var origin := Utils.v2_to_v3(_click_origin_position)
	var destiny: Vector3 = selector.column.position
	_create_temp_wall(origin, destiny)
		
		
func process_build_one_sided_new_point() -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_stop_creating_wall()
	
	if Input.is_action_just_pressed("left_click"):
		var destiny := Utils.v3_to_v2(selector.column.position)
		if destiny == _click_origin_position:
			_stop_creating_wall()
		else:
			_click_origin_position = Utils.v3_to_v2(selector.column.position)
			_wall_being_builded.add_point(_click_origin_position)
			
			Game.server.rpcs.set_wall_points.rpc(map.slug, level.index, 
					_wall_being_builded.id, 
					_wall_being_builded.points_position_2d)
			
			Debug.print_info_message("Wall \"%s\" changed" % _wall_being_builded.id)
			
			
func _stop_creating_wall():
	if _wall_being_builded.curve.point_count < 2:
		_wall_being_builded.remove()
		
		Game.server.rpcs.remove_wall.rpc(map.slug, level.index, _wall_being_builded.id)
		
	_wall_being_builded = null
	selector.wall.visible = false
	

func _create_temp_wall(origin: Vector3, destiny: Vector3) -> void:
	st.clear()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices: PackedVector3Array = [
		origin + Vector3.UP,
		destiny + Vector3.UP,
		origin,
		destiny,
	]
	var normal := Plane(vertices[0], vertices[1], vertices[2]).normal
	
	for i in range(4):
		st.set_normal(normal)
		st.add_vertex(vertices[i])
		
	st.add_index(0)
	st.add_index(1)
	st.add_index(2)

	st.add_index(1)
	st.add_index(3)
	st.add_index(2)
	
	var mesh := st.commit()
	selector.wall.mesh = mesh
	

func process_cutted_wall():
	process_hover_wall()
	
	selector.column.visible = true
	if not _wall_hovered:
		selector.column.visible = false
	
	if _wall_being_builded:
		selector.column.visible = true
		_wall_being_builded.line_renderer_3d.disabled = false
		
		# cutting startes but mouse out of the wall
		if _wall_being_builded != _wall_hovered:
			selector.column.position = _wall_being_builded.curve.get_closest_point(Utils.v2_to_v3(level.position_hovered))
			if _wall_hovered:
				_wall_hovered.line_renderer_3d.disabled = true
				_wall_hovered = null


func process_cut_wall() -> void:
	if _wall_being_builded:
		process_cut_next_point()
		process_cut()
	else:
		process_cut_start()


func process_cut_next_point() -> void:
	if not Game.ui.is_mouse_over_scene_tab:
		return
		
	var origin := Utils.v2_to_v3(_click_origin_position)
	var destiny: Vector3 = selector.column.position
	
	_create_temp_wall(origin, destiny)
	selector.wall.visible = true


func process_cut() -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		_stop_creating_wall()
	
	if Input.is_action_just_released("left_click"):
		if _wall_being_builded:
			var origin := _click_origin_position
			var destiny := Utils.v3_to_v2(selector.column.position)
			_wall_being_builded.cut(origin, destiny)
		_stop_creating_wall()


func process_cut_start() -> void:
	if not Game.ui.is_mouse_over_scene_tab:
		return
		
	if Input.is_action_just_pressed("left_click"):
		_click_origin_position = Utils.v3_to_v2(selector.column.position)
		_wall_being_builded = _wall_hovered
		

func process_build_room(wall_outside := false) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		selector.area.visible = false
		selector.wall.visible = false
		_is_rect_being_builded = false
		
	if Input.is_action_just_pressed("left_click") and Game.ui.is_mouse_over_scene_tab:
		_click_origin_position = Utils.v3_to_v2(selector.column.position)
		selector.wall.visible = true
		_is_rect_being_builded = true
		
	if Input.is_action_pressed("left_click") and Game.ui.is_mouse_over_scene_tab:
		var destiny := Utils.v3_to_v2(selector.column.position)
		selector.move_area_to(_click_origin_position, destiny)
		_create_temp_room(Utils.v2_to_v3(_click_origin_position), selector.column.position)
		
	if Input.is_action_just_released("left_click") and _is_rect_being_builded:
		selector.area.visible = false
		selector.wall.visible = false
		_is_rect_being_builded = false
		
		if not Game.ui.is_mouse_over_scene_tab:
			return
		
		var origin := _click_origin_position
		var destiny := Utils.v3_to_v2(selector.column.position)
		if origin.x == destiny.x or origin.y == destiny.y:
			return
			
		var points := [Vector2(destiny.x, origin.y), destiny, Vector2(origin.x, destiny.y)]
		
		var need_reverse = (destiny - origin).x * (destiny - origin).y < 0
		if need_reverse:
			points.reverse()
		
		if wall_outside:
			points.reverse()
		
		var wall: Wall = map.instancer.create_wall(
				level, Utils.random_string(8, true), [], material_index_selected, randi())
		wall.add_point(origin)
		for point in points:
			wall.add_point(point)
		wall.add_point(origin)
		
		Game.server.rpcs.create_wall.rpc(map.slug, level.index, wall.id, wall.points_position_2d, 
				wall.material_index, wall.material_seed, wall.material_layer, wall.two_sided)
		Game.server.rpcs.set_wall_points.rpc(map.slug, level.index, wall.id, wall.points_position_2d)
			
		Debug.print_info_message("Wall \"%s\" created" % wall.id)


func _create_temp_room(origin: Vector3, destiny: Vector3) -> void:
	var index_offset := 0
	var faces := [
		{"origin": Vector3(origin.x, 0, origin.z), "destiny": Vector3(destiny.x, 0, origin.z)},
		{"origin": Vector3(destiny.x, 0, origin.z), "destiny": Vector3(destiny.x, 0, destiny.z)},
		{"origin": Vector3(destiny.x, 0, destiny.z), "destiny": Vector3(origin.x, 0, destiny.z)},
		{"origin": Vector3(origin.x, 0, destiny.z), "destiny": Vector3(origin.x, 0, origin.z)},
	]
	
	st.clear()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for face in faces:
		_create_temp_room_face(index_offset, face.origin, face.destiny)
		index_offset += 4
	
	var mesh := st.commit()
	selector.wall.mesh = mesh


func _create_temp_room_face(index_offset: int, origin: Vector3, destiny: Vector3) -> void:
	var vertices: PackedVector3Array = [
		origin + Vector3.UP,
		destiny + Vector3.UP,
		origin,
		destiny,
	]
	var normal := Plane(vertices[0], vertices[1], vertices[2]).normal
	
	for i in range(4):
		st.set_normal(normal)
		st.add_vertex(vertices[i])
	
	st.add_index(index_offset + 0)
	st.add_index(index_offset + 1)
	st.add_index(index_offset + 2)

	st.add_index(index_offset + 1)
	st.add_index(index_offset + 3)
	st.add_index(index_offset + 2)


func process_instance_entity():
	var entity := level.preview_element
	if not is_instance_valid(entity):
		entity = map.instancer.create_entity(level, Utils.random_string(8, true), 
				selector.position_2d, _previous_properties, _previous_rotation)
		entity.is_preview = true
		select(entity)
		level.preview_element = entity
		
	entity.is_rotated = Input.is_action_pressed("rotate")
	
	if Input.is_action_just_released("left_click") and Game.ui.is_mouse_over_scene_tab:
		_previous_properties = level.preview_element.properties_values
		_previous_rotation = entity.rotation.y
		level.preview_element = null
		
		if Game.ui.is_mouse_over_scene_tab:
			entity.is_rotated = false
			entity.is_preview = false
			
			Debug.print_info_message("Entity \"%s\" created" % entity.id)
		
			Game.server.rpcs.create_entity.rpc(map.slug, level.index, entity.id, 
					entity.position_2d, entity.properties_values, entity.rotation_y)
				
		else:
			entity.remove()
	

func process_instance_light():
	if not is_instance_valid(level.preview_element):
		level.preview_element = map.instancer.create_light(level, Utils.random_string(8, true), 
				selector.position_2d, _previous_properties)
		level.preview_element.is_preview = true
		select(level.preview_element)
	
	if Input.is_action_just_released("left_click") and Game.ui.is_mouse_over_scene_tab:
		var light := level.preview_element
		Debug.print_info_message("Light \"%s\" created" % light.id)
		light.is_preview = false
		Game.server.rpcs.create_light.rpc(map.slug, level.index, light.id, 
				light.position_2d, light.properties_values, light.rotation_y)

		_previous_properties = level.preview_element.properties_values
		level.preview_element = null
	

func process_instance_shape():
	var shape := level.preview_element
	if not is_instance_valid(shape):
		shape = map.instancer.create_shape(level, Utils.random_string(8, true), 
				selector.position_2d, _previous_properties, _previous_rotation)
		shape.is_preview = true
		select(shape)
		level.preview_element = shape
		
	shape.is_rotated = Input.is_action_pressed("rotate")
	
	if Input.is_action_just_released("left_click") and Game.ui.is_mouse_over_scene_tab:
		_previous_properties = level.preview_element.properties_values
		_previous_rotation = shape.rotation.y
		level.preview_element = null
		
		if Game.ui.is_mouse_over_scene_tab:
			shape.is_rotated = false
			shape.is_preview = false
			
			Debug.print_info_message("Shape \"%s\" created" % shape.id)
		
			Game.server.rpcs.create_shape.rpc(map.slug, level.index, shape.id,
					shape.position_2d, shape.properties_values, shape.rotation_y)
				
		else:
			shape.remove()
		
