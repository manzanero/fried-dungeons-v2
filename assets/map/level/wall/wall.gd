class_name Wall
extends Node3D

signal curve_changed()


var material_index := 0
var material_seed := 0

var level : Level
var points : Array[WallPoint]

var selected_point : WallPoint
var edited_point : WallPoint
var is_edit_mode : bool : set = _set_edit_mode
		
var is_editing : bool


@onready var wall_generator = $WallGenerator as WallGenerator
@onready var path_3d := $Path3D as Path3D
@onready var curve := path_3d.curve as Curve3D
@onready var line_renderer_3d := %LineRenderer3D as LineRenderer
@onready var mesh_instance_3d := $MeshInstance3D as MeshInstance3D
@onready var collision := %StaticBody3D as StaticBody3D
@onready var collider := %CollisionShape3D as CollisionShape3D


func init(_level : Level, _material_index : int, _material_seed : int):
	level = _level
	material_index = _material_index
	material_seed = _material_seed
	level.walls_parent.add_child(self)
	points = []
	is_editing = false
	is_edit_mode = false
	line_renderer_3d.visible = false
	line_renderer_3d.disabled = true
	line_renderer_3d.points.clear()
	name = "Wall"
	return self


func _ready():
	curve_changed.connect(wall_generator._on_curve_changed)
	

func _process(_delta):
	_process_wall_edit()
	
	
func _process_wall_edit():
	if is_editing:
		
		# change end of the wall
		var point_position := level.position_hovered
		if not Input.is_key_pressed(KEY_CTRL):
			point_position = point_position.snapped(Game.SNAPPING_HALF)
		set_point(edited_point, point_position)


func _set_edit_mode(value : bool):
	is_edit_mode = value
	
	if value:
		for wall in level.walls_parent.get_children():
			if wall != self:
				wall.is_edit_mode = false

		level.selected_wall = self
		line_renderer_3d.visible = true
		line_renderer_3d.disabled = false
		Utils.safe_connect(Game.camera.changed, _on_viewport_changed)
		Utils.safe_connect(get_viewport().size_changed, _on_viewport_changed)
		for point in points:
			point.changed.emit()
			
	else:
		level.map.point_options.visible = false
		selected_point = null
		
		level.selected_wall = null
		line_renderer_3d.visible = false
		line_renderer_3d.disabled = true
		Utils.safe_disconnect(Game.camera.changed, _on_viewport_changed)
		Utils.safe_disconnect(get_viewport().size_changed, _on_viewport_changed)
		for point in points:
			point.visible = false
	

func _on_viewport_changed():
	for point in points:
		point.changed.emit()
	
	if selected_point:
		level.map.point_options.visible = not Game.camera.eyes.is_position_behind(selected_point.position_3d)
		level.map.point_options.position = selected_point.position


func add_point(new_position : Vector2, index := -1) -> WallPoint:
	var new_position_3d := Utils.v2_to_v3(new_position)
	index = curve.point_count if index == -1 else index
	curve.add_point(new_position_3d, Vector3.ZERO, Vector3.ZERO, index)
	var wall_point : WallPoint = Game.wall_point_scene.instantiate().init(self, index, new_position_3d)
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
	if curve.point_count <= 1:
		remove()


func select_point(selected_wall_point : WallPoint):
	selected_point = selected_wall_point
	if selected_point:
		level.map.point_options.visible = not Game.camera.eyes.is_position_behind(selected_point.position_3d)
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
	
	if index > 0:
		var new_wall := Game.wall_scene.instantiate().init(level, material_index, material_seed) as Wall
		for point in points.slice(0, index + 1):
			new_wall.add_point(Utils.v3_to_v2(point.position_3d))

		new_wall.is_edit_mode = true

	if index < curve.point_count:
		var new_wall := Game.wall_scene.instantiate().init(level, material_index, material_seed) as Wall
		for point in points.slice(index):
			new_wall.add_point(Utils.v3_to_v2(point.position_3d))

	remove()


func remove():
	queue_free()
	for point in points:
		point.queue_free()

func get_point_by_index(index : int) -> WallPoint:
	return points[index] if index < len(points) else null