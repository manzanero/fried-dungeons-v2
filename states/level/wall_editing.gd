class_name LevelWallEditingState
extends LevelBaseState


enum {
	EDIT_WALL
}

var wall_hovered: Wall
var points_hovered: Array[WallPoint] = []
var points_selected: Array[WallPoint] = []
var dragging: bool
var drag_origin: Vector3 
var point_offsets := {}

var double_click: bool
var mouse_move: bool

var next_update_ticks_msec := Time.get_ticks_msec()

func _enter_state(previous_state: String) -> void:
	super(previous_state)
	Game.ui.build_border.visible = true


func _exit_state(next_state: String) -> void:
	super(next_state)
	Game.ui.build_border.visible = false
	_end_drag()
	_set_hovered([])
	_set_selected([])


func _physics_process_state(_delta: float) -> String:
	Game.ui.build_border.visible = true
	if not level.is_selected:
		return Level.State.GO_BACKGROUND
		
	if Input.is_action_just_pressed("key_c") and wall_hovered:
		Game.ui.tab_builder.material_index_selected = wall_hovered.material_index

	if Input.is_action_just_pressed("ui_cancel"):
		Game.modes.reset()
		return Level.State.GO_IDLE
		
	# dragging ends
	if Input.is_action_just_released("left_click"):
		_end_drag()
		
	if not Game.ui.is_mouse_over_scene_tab or Game.handled_input:
		return Level.State.KEEP
	
	if double_click:
		double_click = false
		_process_new_point()
	elif Input.is_action_just_pressed("delete", true):
		_process_remove_points()
	elif Input.is_action_just_pressed("force_delete"):
		_process_remove_walls()
	else:
		_process_select_points()
	
	if mouse_move:
		mouse_move = false
		_process_drag_points()

	# dragging starts
	if Input.is_action_just_pressed("left_click") and wall_hovered:
		_start_drag()
		
	return Level.State.KEEP


func get_walls_selected() -> Array[Wall]:
	var walls: Array[Wall] = []
	for point in Utils.clean_array(points_selected):
		if not walls.has(point.wall):
			walls.append(point.wall)
	return walls


func sync_wall_changes(wall: Wall):
	Game.server.rpcs.set_wall_points.rpc(
			wall.level.map.slug, wall.level.index, wall.id, wall.points_position_2d)


func repair_wall(wall: Wall):
	if Utils.colapse_points_at_same_position(wall.curve):
		wall.refresh()
	
	if wall.points[0].position_3d.is_equal_approx(wall.points[-1].position_3d):
		wall.is_closed = true


func _end_drag():
	dragging = false
	level.ground_collider.position.y = 0
	point_offsets.clear()
	
	if Utils.clean_array(points_selected).size() == 1 and wall_hovered:
		var point_selected: WallPoint = Utils.clean_array(points_selected)[0]
		var wall_selected := point_selected.wall
		if point_selected.is_last:
			if point_selected.position_3d.is_equal_approx(wall_hovered.first_point.position_3d):
				wall_selected.merge(wall_hovered)
		elif point_selected.is_first:
			if point_selected.position_3d.is_equal_approx(wall_hovered.last_point.position_3d):
				wall_hovered.merge(wall_selected)
				_set_selected([wall_hovered.last_point])  # needs a repair
		
	for wall in get_walls_selected():
		repair_wall(wall)  # Although selected points will be lost
		sync_wall_changes(wall)


func _start_drag():
	level.ground_collider.position.y = drag_origin.y
	
	# wait to ground collider move and to not set "dragging" in this frame
	await get_tree().physics_frame  
	
	dragging = true
	for point in Utils.clean_array(points_selected):
		point_offsets[point] = point.position - drag_origin
	
	_set_hovered([])


func _process_select_points():
	if dragging:
		if Utils.clean_array(points_selected).size() == 1:
			var point_selected: WallPoint = Utils.clean_array(points_selected)[0]
			var wall_selected := point_selected.wall
			
			# check join with another wall
			wall_selected.collider.disabled = true
			await get_tree().physics_frame
			var hit_info_candidate := Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, Game.wall_ray)
			wall_selected.collider.disabled = false
			
			wall_hovered = null
			_set_hovered([])
			
			if hit_info_candidate:
				var wall_candidate := hit_info_candidate.collider.get_parent() as Wall
				if wall_selected.compatible_with(wall_candidate):
					wall_hovered = wall_candidate
					if point_selected.is_last:
						_set_hovered([wall_hovered.first_point])
					elif point_selected.is_first:
						_set_hovered([wall_hovered.last_point])
		return
		
	var hit_info := Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, Game.wall_ray)
	if hit_info:
		wall_hovered = hit_info.collider.get_parent() as Wall
		drag_origin = hit_info.position
		var point_position: Vector3 = Utils.v2_to_v3(Utils.v3_to_v2(hit_info.position))
		var boundary_points := Utils.get_boundary_points(wall_hovered.curve, hit_info.position)
		var point_a_index: int = boundary_points[0]
		var point_b_index: int = boundary_points[1]
		var point_a: WallPoint = wall_hovered.points[point_a_index]
		var point_b: WallPoint = wall_hovered.points[point_b_index]
		var point_a_position := wall_hovered.curve.get_point_position(point_a_index)
		var point_b_position := wall_hovered.curve.get_point_position(point_b_index)
		var point_a_distance := point_position.distance_to(point_a_position)
		var point_b_distance := point_position.distance_to(point_b_position)
		if point_a_distance < point_b_distance and point_a_distance < 0.1:
			_set_hovered([point_a])
		elif point_a_distance > point_b_distance and point_b_distance < 0.1:
			_set_hovered([point_b])
		else:
			_set_hovered([point_a, point_b])
	else:
		wall_hovered = null
		_set_hovered([])
	
	if Input.is_action_just_pressed("shift_left_click"):
		_set_selected_wall(points_hovered, Input.is_key_pressed(KEY_CTRL))
	elif Input.is_action_just_pressed("left_click"):
		_set_selected(points_hovered, Input.is_key_pressed(KEY_CTRL))
		
	if Input.is_action_just_pressed("right_click") and Input.is_key_pressed(KEY_CTRL):
		_set_unselected(points_hovered)


func _set_hovered(points: Array[WallPoint]):
	for point in Utils.clean_array(points_hovered):
		point.is_hovered = false
	points_hovered.clear()
		
	for point in points:
		point.is_hovered = true
		points_hovered.append(point)


func _select(point: WallPoint, value: bool):
	if value:
		point.is_selected = true
		if not points_selected.has(point):
			points_selected.append(point)
	else:
		point.is_selected = false
		points_selected.erase(point)


func _set_selected(points: Array[WallPoint], keep := false):
	if not keep:
		for point in Utils.clean_array(points_selected):
			point.is_selected = false
		points_selected.clear()
	
	for point in points:
		_select(point, true)
		if point.wall.is_closed:
			if point.is_first: 
				_select(point.wall.points[-1], true)
			elif point.is_last: 
				_select(point.wall.points[0], true)


func _set_unselected(points: Array[WallPoint]):
	for point in points:
		_select(point, false)
		if point.wall.is_closed:
			if point.is_first: 
				_select(point.wall.points[-1], false)
			elif point.is_last: 
				_select(point.wall.points[0], false)


func _set_selected_wall(points: Array[WallPoint], keep := false):
	if not keep:
		for point in Utils.clean_array(points_selected):
			point.is_selected = false
		points_selected.clear()
	
	if Utils.clean_array(points_hovered):
		_set_selected(Utils.clean_array(points_hovered)[0].wall.points, true)


func _process_drag_points():
	if not dragging:
		return
		
	if not Utils.clean_array(points_selected):
		return
		
	var hit_info := Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, Game.ground_ray)
	if not hit_info:
		return
		
	var drag_position: Vector3 = hit_info.position
	for point in Utils.clean_array(points_selected):
		if Utils.clean_array(points_selected).size() == 1:
			point.selector.column.visible = true
		
		var new_position: Vector3 = point_offsets[point] + drag_position
		if Input.is_key_pressed(KEY_ALT):
			point.position_3d = new_position.snapped(Game.VOXEL)
		else:
			point.position_3d = new_position.snapped(Game.VOXEL_SNAPPING_QUARTER)
	
	var ticks_msec := Time.get_ticks_msec()
	if next_update_ticks_msec < ticks_msec:
		next_update_ticks_msec = ticks_msec + 100
		for wall in get_walls_selected():
			sync_wall_changes(wall)


func _process_remove_points(): 
	for point in Utils.clean_array(points_selected):
		if point.index == -1:
			continue  # point already delete because wall has 1 point
		if point.wall.is_closed and point.is_last:
			continue  # prevent double delete of first+last point
		point.remove()
	
	points_hovered.clear()
	points_selected.clear()


func _process_remove_walls():
	for wall in get_walls_selected():
		wall.remove()
	
		Game.server.rpcs.remove_wall.rpc(wall.map.slug, wall.level.index, wall.id)


func _process_new_point():
	if points_hovered.size() == 1:
		var point: WallPoint = points_hovered[0]
		if point.wall.is_closed:
			return
			
		if point.is_first:
			var new_point_position := Utils.v3_to_v2(drag_origin)
			var new_point := wall_hovered.add_point(new_point_position, 0)
			_set_hovered([new_point])
			_set_selected([new_point])
		if point.is_last:
			var new_point_position := Utils.v3_to_v2(drag_origin)
			var new_point := wall_hovered.add_point(new_point_position)
			_set_hovered([new_point])
			_set_selected([new_point])
			
	elif points_hovered.size() == 2:
		var next_point: WallPoint = points_hovered[1]
		var new_point_position := Utils.v3_to_v2(drag_origin)
		var new_point := wall_hovered.add_point(new_point_position, next_point.index)
		_set_hovered([new_point])
		_set_selected([new_point])


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click") and event.double_click:
			double_click = true
	
	if event is InputEventMouseMotion:
		mouse_move = true
