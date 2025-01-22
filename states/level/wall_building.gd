class_name LevelWallBuildingState
extends LevelBaseState

enum {
	ONE_SIDED, TWO_SIDED, BARRIER, ROOM, OBSTACLE, PASSAGE,
	PAINT_WALL, CUT_WALL, FLIP_WALL, CHANGE_WALL
}


var mode: int
var material_index_selected: int :
	get: return Game.ui.tab_builder.material_index_selected

var st := SurfaceTool.new()

var _click_origin_position := Game.NULL_POSITION_2D
var _is_rect_being_builded := false
var _wall_being_builded: Wall
var _wall_hovered: Wall


func _enter_state(previous_state: String) -> void:
	super._enter_state(previous_state)
	Game.ui.build_border.visible = true
	
	selector.grid.visible = true
	if mode in [PAINT_WALL, FLIP_WALL, CHANGE_WALL]:
		selector.grid.visible = false
		
	selector.column.visible = true
	if mode in [PAINT_WALL, FLIP_WALL, CHANGE_WALL]:
		selector.column.visible = false
		
	selector.position_2d = Game.NULL_POSITION_2D


func _exit_state(next_state: String) -> void:
	super._exit_state(next_state)
	Game.ui.build_border.visible = false
	selector.wall.mesh = null
	selector.grid.visible = false
	selector.column.visible = false
	_wall_being_builded = null


func _physics_process_state(_delta: float) -> String:
	if not level.is_selected:
		return Level.State.GO_BACKGROUND
	
	if Input.is_action_just_pressed("key_c"):
		var hit_info := Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, Game.wall_ray)
		if hit_info:
			Game.ui.tab_builder.material_index_selected = hit_info.collider.get_parent().material_index
	
	process_ground_hitted()
	
	if Input.is_action_just_pressed("ui_cancel"):
		Game.modes.reset()
		return Level.State.GO_IDLE
	
	match mode:
		ONE_SIDED:
			process_change_grid()
			process_change_column()
			process_build_one_sided()
		TWO_SIDED:
			process_change_grid()
			process_change_column()
			process_build_two_sided()
		BARRIER:
			process_change_grid()
			process_change_column(Game.SNAPPING_QUARTER)
			process_build_barrier(0.25, true)
		PASSAGE:
			process_change_grid()
			process_change_column()
			process_build_passage(0.5, false)
		ROOM:
			process_change_grid()
			process_change_column()
			process_build_room()
		OBSTACLE:
			process_change_grid()
			process_change_column()
			process_build_room(true)
			
		PAINT_WALL:
			process_hover_wall()
			process_paint_wall()
		CUT_WALL:
			process_change_grid()
			process_hover_wall()
			process_cutted_wall()
			process_cut_wall()
		CHANGE_WALL:
			process_hover_wall()
			process_change_wall()
		FLIP_WALL:
			process_hover_wall()
			process_flip_wall()
			
	return ""


func process_hover_wall():
	if not Game.ui.is_mouse_over_scene_tab:
		return
		
	if is_instance_valid(_wall_hovered):
		_wall_hovered.line_renderer_3d.disabled = true
		_wall_hovered.first_point.selector.reset()  # cut mode makes it visible
		_wall_hovered.last_point.selector.reset()  # cut mode makes it visible
	
	var hit_info := Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, Game.wall_ray)
	if hit_info:
		_wall_hovered = hit_info["collider"].get_parent()
		_wall_hovered.line_renderer_3d.disabled = false
		_wall_hovered.first_point.selector.column.visible = true
		_wall_hovered.last_point.selector.column.visible = true
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
	if Input.is_action_just_pressed("right_click"):
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
			
			# detect if closed
			if _click_origin_position == _wall_being_builded.points_position_2d[0]:
				_wall_being_builded.is_closed = true  # no need to send this to players?
				_stop_creating_wall()
			
			
func _stop_creating_wall():
	if _wall_being_builded.curve.point_count < 2:
		_wall_being_builded.remove()
		
		Game.server.rpcs.remove_wall.rpc(map.slug, level.index, _wall_being_builded.id)
		
	_wall_being_builded = null
	selector.wall.visible = false
	selector.wall.mesh.clear_surfaces()
	selector.position_2d = Game.NULL_POSITION_2D
	

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
	if Input.is_action_just_pressed("right_click"):
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
	if Input.is_action_just_pressed("right_click"):
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
		
		#if not Game.ui.is_mouse_over_scene_tab:
			#return
		
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
		wall.is_closed = true
		wall.add_point(origin)
		for point in points:
			wall.add_point(point)
		wall.add_point(origin)
		
		Game.server.rpcs.create_wall.rpc(map.slug, level.index, wall.id, wall.points_position_2d, 
				wall.material_index, wall.material_seed, wall.material_layer, wall.two_sided)
			
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
		

func process_build_barrier(thickness := 0.25, wall_outside := true) -> void:
	if Input.is_action_just_pressed("right_click"):
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
		_create_temp_barrier(Utils.v2_to_v3(_click_origin_position), selector.column.position, thickness)
		
	if Input.is_action_just_released("left_click") and _is_rect_being_builded:
		selector.area.visible = false
		selector.wall.visible = false
		_is_rect_being_builded = false
		
		var origin := _click_origin_position
		var destiny := Utils.v3_to_v2(selector.column.position)
		if origin == destiny:
			return
			
		var direction := origin.direction_to(destiny)
		var pdir := Vector2(-direction.y, direction.x)
			
		var points := [
			origin,
			origin - pdir * thickness, 
			destiny - pdir * thickness,
			destiny, 
			origin,
		]
		
		if wall_outside:
			points.reverse()
		
		var point_snap := Game.SNAPPING_QUARTER
		if Input.is_key_pressed(KEY_ALT):
			point_snap = Game.U
			
		var wall: Wall = map.instancer.create_wall(
				level, Utils.random_string(8, true), [], material_index_selected, randi())
		wall.is_closed = true
		for point in points:
			wall.add_point(point.snappedf(point_snap))
		
		Game.server.rpcs.create_wall.rpc(map.slug, level.index, wall.id, wall.points_position_2d, 
				wall.material_index, wall.material_seed, wall.material_layer, wall.two_sided)
			
		Debug.print_info_message("Wall \"%s\" created" % wall.id)


func _create_temp_barrier(origin: Vector3, destiny: Vector3, thickness: float) -> void:
	var point_snap := Game.SNAPPING_QUARTER
	if Input.is_key_pressed(KEY_ALT):
		point_snap = Game.U
		
	var index_offset := 0
	var direction := origin.direction_to(destiny)
	var pdir := Vector3(-direction.z, 0, direction.x)
	var faces := [
		{"origin": origin, "destiny": destiny},
		{"origin": destiny, "destiny": destiny - pdir * thickness},
		{"origin": destiny - pdir * thickness, "destiny": origin - pdir * thickness},
		{"origin": origin - pdir * thickness, "destiny": origin},
	]
	
	st.clear()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for face in faces:
		_create_temp_room_face(index_offset, face.origin.snappedf(point_snap), face.destiny.snappedf(point_snap))
		index_offset += 4
	
	var mesh := st.commit()
	selector.wall.mesh = mesh
	

func process_build_passage(thickness := 0.5, wall_outside := false) -> void:
	if Input.is_action_just_pressed("right_click"):
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
		_create_temp_passage(Utils.v2_to_v3(_click_origin_position), selector.column.position, thickness)
		
	if Input.is_action_just_released("left_click") and _is_rect_being_builded:
		selector.area.visible = false
		selector.wall.visible = false
		_is_rect_being_builded = false
		
		var origin := _click_origin_position
		var destiny := Utils.v3_to_v2(selector.column.position)
		if origin == destiny:
			return
			
		var direction := origin.direction_to(destiny)
		var pdir := Vector2(-direction.y, direction.x)
			
		var points_1 := [destiny + pdir * thickness, origin + pdir * thickness]
		var points_2 := [origin - pdir * thickness, destiny - pdir * thickness]
		
		if wall_outside:
			points_1.reverse()
			points_2.reverse()
		
		var point_snap := Game.SNAPPING_QUARTER
		if Input.is_key_pressed(KEY_ALT):
			point_snap = Game.U
		
		var wall_1: Wall = map.instancer.create_wall(
				level, Utils.random_string(8, true), [], material_index_selected, randi())
		for point in points_1:
			wall_1.add_point(point.snappedf(point_snap))
		
		Game.server.rpcs.create_wall.rpc(map.slug, level.index, wall_1.id, wall_1.points_position_2d, 
				wall_1.material_index, wall_1.material_seed, wall_1.material_layer, wall_1.two_sided)
				
		Debug.print_info_message("Wall \"%s\" created" % wall_1.id)
		
		var wall_2: Wall = map.instancer.create_wall(
				level, Utils.random_string(8, true), [], material_index_selected, randi())
		for point in points_2:
			wall_2.add_point(point.snappedf(point_snap))
		
		Game.server.rpcs.create_wall.rpc(map.slug, level.index, wall_2.id, wall_2.points_position_2d, 
				wall_2.material_index, wall_2.material_seed, wall_2.material_layer, wall_2.two_sided)
			
		Debug.print_info_message("Wall \"%s\" created" % wall_2.id)
		

func _create_temp_passage(origin: Vector3, destiny: Vector3, thickness: float) -> void:
	var point_snap := Game.SNAPPING_QUARTER
	if Input.is_key_pressed(KEY_ALT):
		point_snap = Game.U
		
	var index_offset := 0
	var direction := origin.direction_to(destiny)
	var pdir := Vector3(-direction.z, 0, direction.x)
	var faces := [
		{"origin": origin + pdir * thickness, "destiny": destiny + pdir * thickness},
		{"origin": origin - pdir * thickness, "destiny": destiny - pdir * thickness},
	]
	
	st.clear()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for face in faces:
		_create_temp_room_face(index_offset, face.origin.snappedf(point_snap), face.destiny.snappedf(point_snap))
		index_offset += 4
	
	var mesh := st.commit()
	selector.wall.mesh = mesh
