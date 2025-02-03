class_name Wall
extends Node3D

const WALL_POINT := preload("res://assets/map/level/wall/wall_point/wall_point.tscn")


var material_index := 0 :
	set(value):
		material_index = value
		refresh_mesh()
var material_seed := 0 :
	set(value):
		material_seed = value
		refresh_mesh()
var material_layer := 1 :
	set(value):
		collision.set_collision_layer_value(material_layer, false)
		material_layer = value
		collision.set_collision_layer_value(material_layer, true)
var two_sided := false :
	set(value):
		two_sided = value
		if value:
			const BACK_SOLID: Material = preload("res://assets/map/level/wall/materials/back_solid.tres")
			mesh_instance_3d.material_overlay = BACK_SOLID
			mesh_instance_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			const BACK: Material = preload("res://assets/map/level/wall/materials/back.tres")
			mesh_instance_3d.material_overlay = BACK
			mesh_instance_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
var is_closed := false

var map: Map
var level: Level
var selected_points: Array[WallPoint] = [] : 
	get:
		selected_points.clear()
		for point in points:
			if point.is_selected:
				selected_points.append(point)
		return selected_points
var hovered_points: Array[WallPoint] = [] : 
	get:
		hovered_points.clear()
		for point in points:
			if point.is_hovered:
				hovered_points.append(point)
		return hovered_points
		

var dirty_points: bool
var dirty_mesh: bool
var dirty_highlight: bool

var id: String :
	set(value): 
		id = value
		name = id

var points: Array[WallPoint] = [] : 
	set(value):
		points.clear()
		for point in value:
			add_point(Utils.v3_to_v2(point.position_3d))
			
var first_point: WallPoint :
	get: return points[0]
			
var last_point: WallPoint :
	get: return points[-1]


func compatible_with(wall: Wall) -> bool:
	if material_index != wall.material_index:
		return false
	if material_layer != wall.material_layer:
		return false
	if two_sided != wall.two_sided:
		return false
	if wall.is_closed:
		return false
	return true


func size() -> int:
	return curve.point_count
	
func clear() -> void:
	Utils.queue_free_children(points_parent)
	curve.clear_points()
	points.clear()


var points_position_2d: PackedVector2Array :
	set(value):
		clear()
		for point in value:
			add_point(point)
	get:
		return points.map(func (wall_point: WallPoint): 
			return wall_point.position_2d
		)
		


var is_selected : bool : set = _set_selected


@onready var points_parent: Node3D = %Points
@onready var generator := $WallGenerator as WallGenerator
@onready var path_3d := $Path3D as Path3D
@onready var curve := path_3d.curve as Curve3D
@onready var line_renderer_3d := %LineRenderer3D as LineRenderer
@onready var mesh_instance_3d := $MeshInstance3D as MeshInstance3D
@onready var collision := %StaticBody3D as StaticBody3D
@onready var collider := %CollisionShape3D as CollisionShape3D


func init(_level: Level, _id: String,
		_material_index := material_index,
		_material_seed := material_seed,
		_material_layer := material_layer,
		_two_sided := two_sided,
		_is_closed := is_closed):
	level = _level
	map = _level.map
	id = _id
	level.walls_parent.add_child(self)
	material_index = _material_index
	material_seed = _material_seed
	material_layer = _material_layer
	two_sided = _two_sided
	is_closed = _is_closed
	
	line_renderer_3d.disabled = true
	line_renderer_3d.points.clear()
	return self


func refresh():
	refresh_points()
	refresh_mesh()
	refresh_highlight()

func refresh_points():
	dirty_points = true
	call_deferred("update")

func refresh_highlight():
	dirty_highlight = true
	call_deferred("update")

func refresh_mesh():
	dirty_mesh = true
	call_deferred("update")


func update() -> void:
	if dirty_points:
		dirty_points = false
		dirty_mesh = true
		update_points()
		
	if dirty_mesh:
		dirty_mesh = false
		dirty_highlight = true
		generator.update_wall()
		
	if dirty_highlight:
		dirty_highlight = false
		update_highlight()


func update_points():
	var point_positions := Utils.get_curve_3d_points_position(curve)
	clear()
	for point_position in point_positions:
		add_point(Utils.v3_to_v2(point_position))


func update_highlight():
	line_renderer_3d.disabled = true
	
	for point in points:
		point.selector.reset()
	
	for point in selected_points:
		line_renderer_3d.disabled = false
		
		var selector: = point.selector
		selector.point.visible = true
		
		var next_point_index := point.index + 1
		if next_point_index < curve.point_count:
			var next_point := points[next_point_index]
			if next_point in selected_points:
				selector.rail.visible = true
				selector.pointer.scale.z = point.position.distance_to(next_point.position)
				if selector.pointer.scale.z:
					selector.pointer.look_at(next_point.position)
	
	for point in hovered_points:
		line_renderer_3d.disabled = false
		
		var selector: = point.selector
		#selector.point.visible = true
		selector.column.visible = true
		
		var next_point_index := point.index + 1
		if next_point_index < curve.point_count:
			var next_point := points[next_point_index]
			if next_point in hovered_points:
				selector.rail.visible = true
				selector.pointer.scale.z = point.position.distance_to(next_point.position)
				if selector.pointer.scale.z:
					selector.pointer.look_at(next_point.position)


func _set_selected(value: bool):
	is_selected = value
	line_renderer_3d.disabled = not value


func add_point(new_position: Vector2, index := -1) -> WallPoint:
	var new_position_3d := Utils.v2_to_v3(new_position)
	index = curve.point_count if index == -1 else index
	curve.add_point(new_position_3d, Vector3.ZERO, Vector3.ZERO, index)
	var wall_point: WallPoint = WALL_POINT.instantiate().init(self, index, new_position_3d)
	wall_point.removed.connect(remove_point.bind(wall_point))
	refresh_mesh()
	
	return wall_point
	

func remove_point(wall_point: WallPoint):
	if is_closed and (wall_point.is_first or wall_point.is_last):
		points[0].queue_free()
		curve.remove_point(0)
		points.erase(points[0])
		points[-1].position_3d = points[0].position_3d
	else:
		wall_point.queue_free()
		curve.remove_point(wall_point.index)
		points.erase(wall_point)

	refresh()

	Debug.print_info_message("Wall \"%s\" changed" % id)
	
	if check():
		Game.server.rpcs.set_wall_points.rpc(map.slug, level.index, id, points_position_2d)
	else:
		Game.server.rpcs.remove_wall.rpc(map.slug, level.index, id)
	

func break_point(broken_wall_point : WallPoint):
	var index := broken_wall_point.index
	if index in [0, curve.point_count - 1]:
		return
		
	var _points_position_2d := points_position_2d
	var wall_1_points_position_2d := _points_position_2d.slice(0, index + 1)
	var wall_2_points_position_2d := _points_position_2d.slice(index)
	
	var wall_1 := map.instancer.create_wall(level, Utils.random_string(8, true),
			wall_1_points_position_2d, material_index, material_seed, material_layer, two_sided)
	level.selected_wall = wall_1
	wall_1.is_selected = true
	Debug.print_info_message("Wall \"%s\" created" % wall_1.id)

	var wall_2 := map.instancer.create_wall(level, Utils.random_string(8, true),
			wall_2_points_position_2d, material_index, material_seed, material_layer, two_sided)
	Debug.print_info_message("Wall \"%s\" created" % wall_2.id)
	
	remove()

	Game.server.rpcs.divide_wall.rpc(map.slug, level.index, id, 
			[wall_1.id, wall_2.id], [wall_1_points_position_2d, wall_2_points_position_2d])
	
	Debug.print_info_message("Wall \"%s\" removed" % id)


func reverse():
	var new_points_position_2d := points_position_2d
	new_points_position_2d.reverse()
	points_position_2d = new_points_position_2d
	
	Game.server.rpcs.set_wall_points.rpc(map.slug, level.index, id, points_position_2d)
		
	Debug.print_info_message("Wall \"%s\" changed" % id)
	
	
func break_points(point_indexes: Array[int]) -> Array[Wall]:
	var walls: Array[Wall] = []
	var walls_points := []
	var wall_points: Array[Vector2] = []
	
	for point in points:
		var index := point.index
		var position_2d := point.position_2d
		wall_points.append(position_2d)
		
		if index in point_indexes:
			walls_points.append(wall_points)
			wall_points = []
			
			if index + 1 not in point_indexes:
				wall_points.append(position_2d)
	
	walls_points.append(wall_points)
	
	if is_closed and walls_points[0][0].is_equal_approx(walls_points[-1][-1]):
		walls_points[-1].resize(walls_points[-1].size() - 1)
		walls_points[0] = walls_points[-1] + walls_points[0]
		walls_points.resize(walls_points.size() - 1)
	
	remove()
	Game.server.rpcs.remove_wall.rpc(map.slug, level.index, id)
	
	for ps in walls_points:
		if ps.size() > 1:
			walls.append(mimic(ps))
	
	return walls
	

func mimic(_points_position_2d: Array[Vector2]) -> Wall:
	var wall := map.instancer.create_wall(level, Utils.random_string(8, true),
			_points_position_2d, material_index, material_seed, material_layer, two_sided)
			
	Game.server.rpcs.create_wall.rpc(map.slug, level.index, 
			wall.id,
			wall.points_position_2d, 
			wall.material_index, 
			wall.material_seed, 
			wall.material_layer, 
			wall.two_sided)
			
	return wall
	
	
func cut(a: Vector2, b: Vector2) -> Array[Wall]:
	if is_closed:
		return cut_closed(a, b)
	else:
		return cut_open(a, b)
	
	
func cut_closed(a: Vector2, b: Vector2) -> Array[Wall]:
	var point_snap := Game.SNAPPING_QUARTER
	if Input.is_key_pressed(KEY_ALT):
		point_snap = Game.U
	
	if curve.get_closest_offset(Utils.v2_to_v3(a)) > curve.get_closest_offset(Utils.v2_to_v3(b)):
		var temp = a
		a = b
		b = temp
	
	var point_1: Vector3
	var point_2: Vector3
	
	var wall := map.instancer.create_wall(level, Utils.random_string(8, true),
			[], material_index, material_seed, material_layer, two_sided)
	
	# first section
	wall.add_point(b.snappedf(point_snap))

	var start_index := Utils.get_boundary_points(curve, Utils.v2_to_v3(b))[1]
	point_1 = Utils.v2_to_v3(b.snappedf(point_snap))
	point_2 = curve.get_point_position(start_index)
	
	if point_1.distance_to(point_2) > 0.031:
		wall.add_point(Utils.v3_to_v2(point_2))
		
	for i in range(start_index + 1, curve.point_count):
		wall.add_point(Utils.v3_to_v2(curve.get_point_position(i)))
	
	# second section
	var end_index := Utils.get_boundary_points(curve, Utils.v2_to_v3(a))[0]
	point_2 = curve.get_point_position(0)  # case first point of 2nd section is 0
	
	for i in range(1, end_index + 1):
		point_1 = curve.get_point_position(i - 1)
		point_2 = curve.get_point_position(i)
		
		wall.add_point(Utils.v3_to_v2(point_2))
		
	point_1 = point_2
	point_2 = Utils.v2_to_v3(a.snappedf(point_snap))
	
	if point_1.distance_to(point_2) > 0.031:
		wall.add_point(Utils.v3_to_v2(point_2))
	
	remove()
	
	Game.server.rpcs.divide_wall.rpc(map.slug, level.index, id, [wall.id], [wall.points_position_2d])
	
	Debug.print_info_message("Wall \"%s\" cutted" % id)
		
	var new_walls: Array[Wall] = []
	if is_instance_valid(wall):
		new_walls.append(wall)
	return new_walls
	
	
func cut_open(a: Vector2, b: Vector2) -> Array[Wall]:
	var point_snap := Game.SNAPPING_QUARTER
	if Input.is_key_pressed(KEY_ALT):
		point_snap = Game.U
	
	var segment_1_offset := curve.get_closest_offset(Utils.v2_to_v3(a))
	var segment_2_offset := curve.get_closest_offset(Utils.v2_to_v3(b))
	
	if segment_1_offset > segment_2_offset:
		var temp = a
		a = b
		b = temp
		temp = segment_1_offset
		segment_1_offset = segment_2_offset
		segment_2_offset = temp
	
	var offset := 0.0
	var index := 0
	var point_1: Vector3
	var point_2: Vector3
	var delta := 0.0
	
	var wall_1 := map.instancer.create_wall(level, Utils.random_string(8, true),
			[], material_index, material_seed, material_layer, two_sided)
	wall_1.add_point(Utils.v3_to_v2(curve.get_point_position(0)))
	
	for i in range(1, curve.point_count):
		index = i
		point_1 = curve.get_point_position(i - 1)
		point_2 = curve.get_point_position(i)
		delta = point_1.distance_to(point_2)
		offset += delta
		if offset < segment_1_offset:
			wall_1.add_point(Utils.v3_to_v2(point_2))
			continue
		elif point_1.distance_to(Utils.v2_to_v3(a.snappedf(point_snap))) > 0.031:
			wall_1.add_point(a.snappedf(point_snap))
		break
	
	Debug.print_info_message("Wall \"%s\" created" % wall_1.id)
	
	var wall_1_created := wall_1.check()
		
	var wall_2 := map.instancer.create_wall(level, Utils.random_string(8, true),
			[], material_index, material_seed, material_layer, two_sided)
	wall_2.add_point(b.snappedf(point_snap))
	
	# first point of 2nd wall may be in the same index
	point_1 = Utils.v2_to_v3(b.snappedf(point_snap))
	point_2 = curve.get_point_position(index)
	delta = point_1.distance_to(point_2)
	
	if offset > segment_2_offset and delta > 0.031:
		wall_2.add_point(Utils.v3_to_v2(point_2))
		
	for i in range(index + 1, curve.point_count):
		index = i
		point_1 = curve.get_point_position(i - 1)
		point_2 = curve.get_point_position(i)
		delta = point_1.distance_to(point_2)
		offset += delta
		if offset > segment_2_offset and delta > 0.031:
			wall_2.add_point(Utils.v3_to_v2(point_2))
	
	if curve.get_point_position(curve.point_count - 1).distance_to(Utils.v2_to_v3(b.snappedf(point_snap))) < 0.031:
		wall_2.remove()
	
	Debug.print_info_message("Wall \"%s\" created" % wall_2.id)
	
	var wall_2_created := wall_2.check()
	
	if wall_2_created and curve.get_point_position(curve.point_count - 1).distance_to(
			Utils.v2_to_v3(b.snappedf(point_snap))) < 0.031:
		wall_2.remove()
		wall_2_created = false
			
	remove()

	var new_wall_ids := []
	var new_wall_points := []
	if wall_1_created:
		new_wall_ids.append(wall_1.id)
		new_wall_points.append(wall_1.points_position_2d)
	if wall_2_created:
		new_wall_ids.append(wall_2.id)
		new_wall_points.append(wall_2.points_position_2d)
	
	Game.server.rpcs.divide_wall.rpc(map.slug, level.index, id, new_wall_ids, new_wall_points)
	
	var new_walls: Array[Wall] = []
	if is_instance_valid(wall_1):
		new_walls.append(wall_1)
	if is_instance_valid(wall_2):
		new_walls.append(wall_2)
	return new_walls


func merge(wall: Wall):
	for point in wall.points:
		add_point(point.position_2d)
	
	wall.remove()
	
	Game.server.rpcs.set_wall_points.rpc(map.slug, level.index, id, points_position_2d)
	Game.server.rpcs.remove_wall.rpc(map.slug, level.index, wall.id)


func check() -> bool:
	if not is_instance_valid(self) or curve.point_count < 2 or (is_closed and curve.point_count < 3):
		remove()
		return false
	return true


func remove():
	collider.disabled = true
	
	# cut operation replaces the wall but the refresh needs one frame to rebuild the new ones
	await get_tree().process_frame
	await get_tree().process_frame
	
	queue_free()
	for point in points:
		point.queue_free()
				
	Debug.print_info_message("Wall \"%s\" removed" % id)


###############
# Serializing #
###############

func json():
	var p := []
	for point in points:
		p.append(Utils.v3_to_a2(point.position))
		
	var wall := {
		"id": id,
		"i": material_index,
		"s": material_seed,
		"p": p,
	}
	if material_layer != 1:
		wall["l"] = material_layer
	if two_sided:
		wall["2"] = two_sided
	if is_closed:
		wall["c"] = is_closed
	
	return wall
	
	
