class_name Wall
extends Node3D


signal curve_changed()


@export var material_index := 0 :
	set(value):
		material_index = value
		curve_changed.emit()
@export var material_seed := 0 :
	set(value):
		material_seed = value
		curve_changed.emit()
@export var material_layer := 1 :
	set(value):
		material_layer = value
		if is_inside_tree():
			collision.set_collision_layer_value(material_layer, false)
			collision.set_collision_layer_value(value, true)
@export var two_sided := false :
	set(value):
		two_sided = value
		if is_inside_tree():
			if value:
				const BACK_SOLID: Material = preload("res://assets/map/level/wall/materials/back_solid.tres")
				mesh_instance_3d.material_overlay = BACK_SOLID
				mesh_instance_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			else:
				mesh_instance_3d.material_overlay = null
				#const BACK: Material = preload("res://assets/map/level/wall/materials/back.tres")
				#mesh_instance_3d.material_overlay = BACK
				#mesh_instance_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

var map: Map
var level: Level

var id: String :
	set(value): 
		id = value
		name = id

var points: Array[WallPoint] = [] : 
	set(value):
		points.clear()
		for point in value:
			add_point(Utils.v3_to_v2(point.position_3d))
		
var points_position_2d := PackedVector2Array() :
	set(value):
		for wall_point: WallPoint in points:
			wall_point.remove()
		curve.clear_points()
		points.clear()
		for point in value:
			add_point(point)
	get:
		points_position_2d.clear()
		for point in points:
			points_position_2d.append(Utils.v3_to_v2(point.position_3d))
		return points_position_2d

var selected_point : WallPoint
var edited_point : WallPoint
var is_selected : bool : set = _set_selected
		
var is_editing : bool


@onready var wall_generator = $WallGenerator as WallGenerator
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
		_two_sided := two_sided):
	level = _level
	map = _level.map
	id = _id
	level.walls_parent.add_child(self)
	material_index = _material_index
	material_seed = _material_seed
	material_layer = _material_layer
	two_sided = _two_sided
	
	line_renderer_3d.disabled = true
	line_renderer_3d.points.clear()
	return self


func _physics_process(_delta: float) -> void:
	_process_wall_edit()
	
	
func _process_wall_edit():
	if is_editing:
		
		# change end of the wall
		var point_position_2d := level.position_hovered
		if not Input.is_key_pressed(KEY_CTRL):
			point_position_2d = point_position_2d.snapped(Game.PIXEL_SNAPPING_QUARTER)
		set_point(edited_point, point_position_2d)
		
		Debug.print_info_message("Wall \"%s\" setted point %s" % [id, edited_point.index])
		
		Game.server.rpcs.set_wall_point.rpc(map.slug, level.index, id, edited_point.index, point_position_2d)


func _set_selected(value: bool):
	is_selected = value
	
	if value:
		line_renderer_3d.disabled = false
		Utils.safe_connect(level.map.camera.changed, _on_viewport_changed)
		Utils.safe_connect(get_viewport().size_changed, _on_viewport_changed)
		for point in points:
			point.changed.emit()
			
	else:
		is_editing = false
		level.map.point_options.visible = false
		selected_point = null
		line_renderer_3d.disabled = true
		Utils.safe_disconnect(level.map.camera.changed, _on_viewport_changed)
		Utils.safe_disconnect(get_viewport().size_changed, _on_viewport_changed)
		for point in points:
			point.visible = false


func _on_viewport_changed():
	for point in points:
		point.changed.emit()
	
	if selected_point:
		level.map.point_options.visible = not level.map.camera.eyes.is_position_behind(selected_point.position_3d)
		level.map.point_options.position = selected_point.position


func add_point(new_position: Vector2, index := -1) -> WallPoint:
	var new_position_3d := Utils.v2_to_v3(new_position)
	index = curve.point_count if index == -1 else index
	curve.add_point(new_position_3d, Vector3.ZERO, Vector3.ZERO, index)
	var wall_point: WallPoint = Game.wall_point_scene.instantiate().init(self, index, new_position_3d)
	curve_changed.emit()
	
	return wall_point


func set_point(wall_point : WallPoint, point_position : Vector2):
	var point_position_3d := Utils.v2_to_v3(point_position)
	
	curve.set_point_position(wall_point.index, point_position_3d)
	wall_point.position_3d = point_position_3d
	curve_changed.emit()
	

func remove_point(removed_wall_point : WallPoint):
	removed_wall_point.queue_free()
	curve.remove_point(removed_wall_point.index)
	points.erase(removed_wall_point)
	curve_changed.emit()

	Debug.print_info_message("Wall \"%s\" changed" % id)
	
	if check():
		Game.server.rpcs.set_wall_points.rpc(map.slug, level.index, id, points_position_2d)
	else:
		Game.server.rpcs.remove_wall.rpc(map.slug, level.index, id)
				
	

func select_point(selected_wall_point : WallPoint):
	selected_point = selected_wall_point
	if selected_point:
		level.map.point_options.visible = not level.map.camera.eyes.is_position_behind(selected_point.position_3d)
		level.map.point_options.position = selected_point.position
	else:
		level.map.point_options.visible = false


func edit_point(edited_wall_point : WallPoint):
	if edited_wall_point:
		is_editing = true
		edited_point = edited_wall_point
	else:
		is_editing = false
		edited_point = null
	

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
	
	
func cut(a: Vector2, b: Vector2):
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
		elif point_1.distance_to(Utils.v2_to_v3(a.snapped(Game.PIXEL))) > 0.031:
			wall_1.add_point(a.snapped(Game.PIXEL))
		break
	
	Debug.print_info_message("Wall \"%s\" created" % wall_1.id)
	
	var wall_1_created := wall_1.check()
		
	var wall_2 := map.instancer.create_wall(level, Utils.random_string(8, true),
			[], material_index, material_seed, material_layer, two_sided)
	wall_2.add_point(b.snapped(Game.PIXEL))
	
	# first point of 2nd wall may be in the same index
	point_1 = Utils.v2_to_v3(b.snapped(Game.PIXEL))
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
	
	if curve.get_point_position(curve.point_count - 1).distance_to(Utils.v2_to_v3(b.snapped(Game.PIXEL))) < 0.031:
		wall_2.remove()
	
	Debug.print_info_message("Wall \"%s\" created" % wall_2.id)
	
	var wall_2_created := wall_2.check()
	
	if wall_2_created and curve.get_point_position(curve.point_count - 1).distance_to(
			Utils.v2_to_v3(b.snapped(Game.PIXEL))) < 0.031:
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


func get_point_by_index(index : int) -> WallPoint:
	return points[index] if index < len(points) else null


func check() -> bool:
	if curve.point_count < 2 or not is_instance_valid(self):
		remove()
		return false
	return true

func remove():
	level.map.point_options.visible = false
	
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
		p.append(Utils.v3_to_a2(point.position_3d))
	
	return {
		"id": id,
		"i": material_index,
		"s": material_seed,
		"l": material_layer,
		"2": two_sided,
		"p": p,
	}
	
	
