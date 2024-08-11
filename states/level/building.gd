class_name LevelBuildingState
extends LevelBaseState


var mode: int
var material_index_selected: int :
	get:
		return Game.ui.tab_builder.material_index_selected

var st := SurfaceTool.new()

var _click_origin_position := Vector2.ZERO
var _click_origin_tile := Vector2i.ZERO
var _is_rect_being_builded := false
var _wall_being_builded: Wall
var _wall_hovered: Wall


var _is_something_being_builded: bool :
	get:
		return _is_rect_being_builded or _wall_being_builded


func _enter_state(previous_state: String) -> void:
	super._enter_state(previous_state)
	
	Game.ui.build_border.visible = true
		
	match mode:
		TabBuilder.PAINT_TILE:
			selector.grid.visible = true
		TabBuilder.PAINT_RECT:
			selector.grid.visible = true
		TabBuilder.PAINT_WALL:
			pass
		TabBuilder.ONE_SIDED:
			selector.grid.visible = true
			selector.column.visible = true
		TabBuilder.TWO_SIDED:
			selector.grid.visible = true
			selector.column.visible = true
		TabBuilder.ROOM:
			selector.grid.visible = true
			selector.column.visible = true
		TabBuilder.OBSTACLE:
			selector.grid.visible = true
			selector.column.visible = true
		TabBuilder.CUT:
			selector.column.visible = true


func _exit_state(next_state: String) -> void:
	super._exit_state(next_state)
	selector.grid.visible = false
	selector.column.visible = false
	selector.wall.visible = false
	selector.wall.mesh = null
	_wall_being_builded = null
	
	Game.ui.build_border.visible = false


func _physics_process_state(_delta: float) -> String:
	process_ground_hitted()
	
	if Input.is_action_just_pressed("ui_cancel") and not _is_something_being_builded:
		var button := Game.ui.tab_builder.tile_button.button_group.get_pressed_button()
		if button:
			button.button_pressed = false
		return "Idle"
	
	match mode:
		TabBuilder.ONE_SIDED:
			process_change_grid()
			process_change_column()
			process_build_one_sided()
		TabBuilder.TWO_SIDED:
			process_change_grid()
			process_change_column()
			process_build_two_sided()
		TabBuilder.ROOM:
			process_change_grid()
			process_change_column()
			process_build_room()
		TabBuilder.OBSTACLE:
			process_change_grid()
			process_change_column()
			process_build_room(true)
			
		TabBuilder.MOVE:
			process_wall_selection()
		TabBuilder.CUT:
			process_cutted_wall()
			process_cut_wall()
		TabBuilder.CHANGE:
			process_hover_wall()
			process_change_wall()
		TabBuilder.FLIP:
			process_hover_wall()
			process_flip_wall()
		TabBuilder.PAINT_WALL:
			process_hover_wall()
			process_paint_wall()
			
		TabBuilder.PAINT_TILE:
			process_change_grid()
			process_build_point()
		TabBuilder.PAINT_RECT:
			process_change_grid()
			process_build_rect()
			
	return ""


func process_change_grid() -> void:
	if not Game.ui.is_mouse_over_map_tab:
		return
		
	selector.move_grid_to(level.position_hovered)


func process_change_column() -> void:
	if not Game.ui.is_mouse_over_map_tab:
		return
		
	var point_position := level.position_hovered
	if not Input.is_key_pressed(KEY_CTRL):
		point_position = point_position.snapped(Game.PIXEL_SNAPPING_QUARTER)
		
	selector.column.position = Utils.v2_to_v3(point_position)


func process_build_point() -> void:
	if Input.is_action_just_pressed("left_click") and Game.ui.is_mouse_over_map_tab:
		selector.area.visible = true
		
	if Input.is_action_pressed("left_click") and _click_origin_tile != level.tile_hovered and Game.ui.is_mouse_over_map_tab:
		_click_origin_tile = level.tile_hovered
		selector.tiled_move_area_to(level.position_hovered, level.position_hovered)
		var random = range(8).pick_random()
		level.viewport_3d.tile_map_set_cell(level.tile_hovered, Vector2i(random, material_index_selected))
	
	if Input.is_action_just_released("left_click") and Game.ui.is_mouse_over_map_tab:
		selector.area.visible = false


func process_build_rect() -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		selector.area.visible = false
		_is_rect_being_builded = false
		
	if Input.is_action_just_pressed("left_click") and Game.ui.is_mouse_over_map_tab:
		_click_origin_position = level.position_hovered
		_is_rect_being_builded = true
		selector.area.visible = true
		
	if Input.is_action_pressed("left_click") and Game.ui.is_mouse_over_map_tab:
		selector.tiled_move_area_to(_click_origin_position, level.position_hovered)
		
	if Input.is_action_just_released("left_click") and _is_rect_being_builded:
		selector.area.visible = false
		_is_rect_being_builded = false
		
		if Game.ui.is_mouse_over_map_tab:
			var init_x := int(_click_origin_position.floor().x)
			var init_y := int(_click_origin_position.floor().y)
			var end_x := level.tile_hovered.x
			var end_y := level.tile_hovered.y
			var dir_x := 1 if end_x > init_x else -1
			var dir_y := 1 if end_y > init_y else -1
			for x in range(init_x, end_x + dir_x, dir_x):
				for y in range(init_y, end_y + dir_y, dir_y):
					var random = range(8).pick_random()
					level.viewport_3d.tile_map_set_cell(Vector2i(x, y), Vector2i(random, material_index_selected))


func process_hover_wall():
	if not Game.ui.is_mouse_over_map_tab:
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
	if not Game.ui.is_mouse_over_map_tab:
		return
		
	if not is_instance_valid(_wall_hovered):
		return
		
	if Input.is_action_just_pressed("left_click"):
		_wall_hovered.two_sided = not _wall_hovered.two_sided

		
func process_flip_wall() -> void:
	if not Game.ui.is_mouse_over_map_tab:
		return
		
	if not is_instance_valid(_wall_hovered):
		return
		
	if Input.is_action_just_pressed("left_click"):
		_wall_hovered.reverse()


func process_paint_wall() -> void:
	if not Game.ui.is_mouse_over_map_tab:
		return
		
	if not is_instance_valid(_wall_hovered):
		return
		
	if Input.is_action_just_pressed("left_click"):
		_wall_hovered.material_index = material_index_selected


func process_build_one_sided() -> void:
	if not Game.ui.is_mouse_over_map_tab:
		return
		
	if _wall_being_builded:
		process_build_one_sided_next_point()
		process_build_one_sided_new_point()
	else:
		process_build_one_sided_start()
		

func process_build_two_sided() -> void:
	if not Game.ui.is_mouse_over_map_tab:
		return
		
	if _wall_being_builded:
		process_build_one_sided_next_point()
		process_build_one_sided_new_point()
	else:
		process_build_one_sided_start(true)
		

func process_build_one_sided_start(two_sided := false) -> void:
	if Input.is_action_just_pressed("left_click"):
		_click_origin_position = Utils.v3_to_v2(selector.column.position)
		_wall_being_builded = Game.wall_scene.instantiate().init(level, 5, randi())
		_wall_being_builded.add_point(_click_origin_position)
		if two_sided:
			_wall_being_builded.two_sided = true
			
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
			
			
func _stop_creating_wall():
	if _wall_being_builded.curve.point_count < 2:
		_wall_being_builded.remove()
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
	
	if _wall_being_builded:
		_wall_being_builded.line_renderer_3d.disabled = false
		selector.reset_vanish()
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
	if not Game.ui.is_mouse_over_map_tab:
		return
		
	var origin := Utils.v2_to_v3(_click_origin_position)
	var destiny: Vector3 = selector.column.position
	
	_create_temp_wall(origin, destiny)
	selector.wall.visible = true
	
	#if _wall_hovered:
		#selector.wall.visible = true
		#_create_temp_wall(origin, destiny)
	#else:
		#selector.wall.visible = false


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
	if not Game.ui.is_mouse_over_map_tab:
		return
		
	if Input.is_action_just_pressed("left_click"):
		_click_origin_position = Utils.v3_to_v2(selector.column.position)
		_wall_being_builded = _wall_hovered
		

func process_build_room(wall_outside := false) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		selector.area.visible = false
		selector.wall.visible = false
		_is_rect_being_builded = false
		
	if Input.is_action_just_pressed("left_click") and Game.ui.is_mouse_over_map_tab:
		_click_origin_position = Utils.v3_to_v2(selector.column.position)
		selector.wall.visible = true
		_is_rect_being_builded = true
		
	if Input.is_action_pressed("left_click") and Game.ui.is_mouse_over_map_tab:
		var destiny := Utils.v3_to_v2(selector.column.position)
		selector.move_area_to(_click_origin_position, destiny)
		_create_temp_room(Utils.v2_to_v3(_click_origin_position), selector.column.position)
		
	if Input.is_action_just_released("left_click") and _is_rect_being_builded:
		selector.area.visible = false
		selector.wall.visible = false
		_is_rect_being_builded = false
		
		if not Game.ui.is_mouse_over_map_tab:
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
		
		var wall: Wall = Game.wall_scene.instantiate().init(level, 5, randi())
		wall.add_point(origin)
		for point in points:
			wall.add_point(point)
		wall.add_point(origin)
				

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
