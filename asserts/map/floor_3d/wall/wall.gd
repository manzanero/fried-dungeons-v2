class_name Wall
extends Node3D

const SNAPPING := Vector2.ONE * Game.PIXEL_SIZE * 8

signal curve_changed()
signal edit_mode_started()
signal edit_mode_ended()
signal editing_started()
signal editing_ended()


var floor_3d : Floor3D

var selected_point : WallPoint
var edited_point : WallPoint
var is_edit_mode : bool : 
	set(value): 
		is_edit_mode = value
		if value:
			edit_mode_started.emit()
		else:
			edit_mode_ended.emit()
		
var is_editing : bool :
	set(value): 
		is_editing = value
		if value:
			editing_started.emit()
		else:
			editing_ended.emit()

var origin_distance_offset := 0.0
var st := SurfaceTool.new()
var atlas_texture := AtlasTexture.new()
var atlas_image := Image.new()


@onready var path_3d := $Path3D as Path3D
@onready var curve := path_3d.curve as Curve3D
@onready var mesh_instance_3d := $MeshInstance3D as MeshInstance3D
@onready var collision := %StaticBody3D as StaticBody3D
@onready var collider := %CollisionShape3D as CollisionShape3D
@onready var canvas_layer := $CanvasLayer as CanvasLayer
@onready var points_parent := %Points as Control


func init(_floor_3d):
	floor_3d = _floor_3d
	floor_3d.walls_parent.add_child(self)
	name = "Wall"
	return self


func _ready():
	curve_changed.connect(_on_curve_changed)
	edit_mode_started.connect(_on_edit_mode_started)
	edit_mode_ended.connect(_on_edit_mode_ended)
	collision.input_event.connect(_on_input_event)  #(camera:Node, event:InputEvent, position:Vector3, normal:Vector3, shape_idx:int)
	
	# set init state
	is_editing = false
	is_edit_mode = false
	

func _process(_delta):
	_process_edit()
	
	
func _process_edit():
	if is_editing:
		floor_3d.hit_floor.emit()
		
		# change end of the wall
		var point_position := floor_3d.position_hovered
		if not Input.is_key_pressed(KEY_CTRL):
			point_position = point_position.snapped(SNAPPING)
		set_point(edited_point, point_position)
				
		curve_changed.emit()
	
	
func _on_curve_changed():
	st.clear()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var index_offset := 0
	var origin_offset := origin_distance_offset
	for waypoint_index in range(curve.point_count - 1):
		var origin_point := curve.get_point_position(waypoint_index)
		var destiny_point := curve.get_point_position(waypoint_index + 1)
		var distance := origin_point.distance_to(destiny_point)
		var direction := origin_point.direction_to(destiny_point)
		
		if origin_offset:
			var face_size := minf(1 - origin_offset, distance)
			var intermediate_point := origin_point + direction * face_size
			var destiny_offset := origin_offset + face_size
			
			_create_face(origin_point, intermediate_point, index_offset, origin_offset, destiny_offset)
			index_offset += 4
			origin_point = intermediate_point
			
			if distance == face_size:
				origin_offset = destiny_offset
				continue
				
			distance -= face_size
		
		while distance > 1:
			var intermediate_point := origin_point + direction
			
			_create_face(origin_point, intermediate_point, index_offset)
			index_offset += 4
			origin_point = intermediate_point
			distance -= 1
		
		_create_face(origin_point, destiny_point, index_offset, 0.0, distance)
		index_offset += 4
		
		origin_offset = distance
		
	st.generate_normals()
	
	mesh_instance_3d.mesh = st.commit()
	collider.shape = mesh_instance_3d.mesh.create_trimesh_shape()


func _create_face(origin : Vector3, destiny : Vector3, index_offset : int, origin_offset := 0.0, destiny_offset := 1.0):
	var vertices : PackedVector3Array = [
		origin + Vector3.UP,
		destiny + Vector3.UP,
		origin,
		destiny,
	]
	var uvs := _get_uvs(Vector2i(0, 1), origin_offset, destiny_offset)

	for i in range(4):
		st.set_uv(uvs[i])
		st.add_vertex(vertices[i])
		
	st.add_index(index_offset)
	st.add_index(index_offset + 1)
	st.add_index(index_offset + 2)

	st.add_index(index_offset + 1)
	st.add_index(index_offset + 3)
	st.add_index(index_offset + 2)
	
	
func _get_uvs(xy: Vector2i, origin_margin := 0.0, destiny_margin := 1.0) -> PackedVector2Array:
	const HEIGHT_ATLAS := 64
	const WIDTH_ATLAS := 8
	const W_UNIT := 1.0 / WIDTH_ATLAS
	const H_UNIT := 1.0 / HEIGHT_ATLAS
	const PIXEL := Vector2(W_UNIT, H_UNIT) / 16
	var offset := Vector2(W_UNIT * xy.x, H_UNIT * xy.y)
	return [
		offset + Vector2(W_UNIT * origin_margin, 0).snapped(PIXEL),
		offset + Vector2(W_UNIT * destiny_margin, 0).snapped(PIXEL),
		offset + Vector2(W_UNIT * origin_margin, H_UNIT).snapped(PIXEL),
		offset + Vector2(W_UNIT * destiny_margin, H_UNIT).snapped(PIXEL),
	]


func _on_edit_mode_started():
	for wall in floor_3d.walls_parent.get_children():
		if wall == self:
			canvas_layer.visible = true
		else:
			wall.is_edit_mode = false


func _on_edit_mode_ended():
	canvas_layer.visible = false


func _on_point_selected(selected_wall_point : WallPoint):
	for wall_point in points_parent.get_children():
		wall_point.options.visible = false
		
	if selected_wall_point:
		selected_wall_point.options.visible = true
	

func _on_point_removed(removed_wall_point : WallPoint):
	removed_wall_point.queue_free()
	curve.remove_point(removed_wall_point.index)
	curve_changed.emit()
	if curve.point_count <= 1:
		queue_free()


func _on_point_edited(edited_wall_point : WallPoint):
	if edited_wall_point:
		is_editing = true
		edited_point = edited_wall_point
	else:
		is_editing = false
		edited_point = null
	

func _on_point_broken(broken_wall_point : WallPoint):
	var index := broken_wall_point.index
	
	if index > 0:
		var new_wall := Game.wall_scene.instantiate().init(floor_3d) as Wall
		for wall_point in points_parent.get_children().slice(0, index + 1):
			new_wall.add_point(Utils.v3_to_v2(wall_point.position_3d))
	
		#new_wall.is_edit_mode = true
	
	if index < curve.point_count:
		var new_wall := Game.wall_scene.instantiate().init(floor_3d) as Wall
		for wall_point in points_parent.get_children().slice(index):
			new_wall.add_point(Utils.v3_to_v2(wall_point.position_3d))
		
	queue_free()


func add_point(new_position : Vector2, index := -1) -> WallPoint:
	var point_position_3d := Utils.v2_to_v3(new_position)
	index = curve.point_count if index == -1 else index
	curve.add_point(point_position_3d, Vector3.ZERO, Vector3.ZERO, index)
	var wall_point : WallPoint = Game.wall_point_scene.instantiate().init(self, index, point_position_3d)
	wall_point.selected.connect(_on_point_selected)
	wall_point.removed.connect(_on_point_removed)
	wall_point.edited.connect(_on_point_edited)
	wall_point.broken.connect(_on_point_broken)
	curve_changed.emit()
	return wall_point


func set_point(wall_point : WallPoint, point_position : Vector2):
	var point_position_3d := Utils.v2_to_v3(point_position)
	
	curve.set_point_position(wall_point.index, point_position_3d)
	wall_point.position_3d = point_position_3d


func get_point_by_index(index : int) -> WallPoint:
	var wall_points := points_parent.get_children()
	return wall_points[index] if index < len(wall_points) else null
	

func _on_input_event(_camera : Node, event : InputEvent, _position : Vector3, _normal : Vector3, _shape_idx : int):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_edit_mode = not is_edit_mode
			curve_changed.emit()
		#if event.double_click:
			#is_edit_mode = not is_edit_mode
			#curve_changed.emit()
