class_name WallGenerator
extends Node


var origin_distance_offset := 0.0

var st := SurfaceTool.new()
var atlas_texture := AtlasTexture.new()
var atlas_image := Image.new()


@onready var wall := $".." as Wall


func _ready() -> void:
	wall.curve_changed.connect(_on_curve_changed)


func _on_curve_changed():
	seed(wall.material_seed)
	st.clear()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var index_offset := 0
	var origin_offset := origin_distance_offset
	var curve := wall.curve
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
	
	var mesh := st.commit()
	wall.mesh_instance_3d.mesh = mesh
	var shape := mesh.create_trimesh_shape()
	if shape:
		shape.backface_collision = true
	wall.collider.shape = shape
	wall.line_renderer_3d.points.resize(curve.point_count)
	for index in range(curve.point_count):
		wall.line_renderer_3d.points[index] = curve.get_point_position(index)
	for point in wall.points:
		point.changed.emit()
	

func _create_face(origin : Vector3, destiny : Vector3, index_offset : int, origin_offset := 0.0, destiny_offset := 1.0):
	var vertices : PackedVector3Array = [
		origin + Vector3.UP,
		destiny + Vector3.UP,
		origin,
		destiny,
	]
	var uvs := _get_uvs(origin_offset, destiny_offset)
	var normal := Plane(vertices[0], vertices[1], vertices[2]).normal

	for i in range(4):
		st.set_uv(uvs[i])
		st.set_normal(normal)
		st.add_vertex(vertices[i])
		
	st.add_index(index_offset)
	st.add_index(index_offset + 1)
	st.add_index(index_offset + 2)

	st.add_index(index_offset + 1)
	st.add_index(index_offset + 3)
	st.add_index(index_offset + 2)
	
	
func _get_uvs(origin_margin := 0.0, destiny_margin := 1.0) -> PackedVector2Array:
	const HEIGHT_ATLAS := 64
	const WIDTH_ATLAS := 8
	const W_UNIT := 1.0 / WIDTH_ATLAS
	const H_UNIT := 1.0 / HEIGHT_ATLAS
	const PIXEL := Vector2(W_UNIT, H_UNIT) / 16
	var offset := Vector2(W_UNIT * range(4).pick_random(), H_UNIT * wall.material_index)
	return [
		(offset + Vector2(W_UNIT * origin_margin, 0)).snapped(PIXEL),
		(offset + Vector2(W_UNIT * destiny_margin, 0)).snapped(PIXEL),
		(offset + Vector2(W_UNIT * origin_margin, H_UNIT)).snapped(PIXEL),
		(offset + Vector2(W_UNIT * destiny_margin, H_UNIT)).snapped(PIXEL),
	]
