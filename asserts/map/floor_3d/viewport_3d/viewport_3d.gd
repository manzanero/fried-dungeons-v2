class_name Viewport3D
extends MeshInstance3D


signal rect_changed()


@onready var viewport := $SubViewport as SubViewport
@onready var floor_2d := $SubViewport/Floor2D as Floor2D
@onready var tile_map := floor_2d.tile_map


func _ready():
	
	# Viewports cannot start with texture
	var mesh_material := get_surface_override_material(0) as StandardMaterial3D
	mesh_material.albedo_texture = viewport.get_texture()
	
	rect_changed.connect(_on_rect_changed)
	
	# set init state
	_on_rect_changed()
	

func _on_rect_changed():
	var tile_size = tile_map.tile_set.tile_size.x
	var rect := tile_map.get_used_rect()
	var rect_position := rect.position
	var rect_size := rect.size
	
	floor_2d.position = -rect_position * tile_size
	viewport.size = rect_size * tile_size
	position = Vector3(rect_position.x + rect_size.x / 2.0, 0, rect_position.y + rect_size.y / 2.0)
	(mesh as PlaneMesh).size = rect.size

	Debug.print_message(Debug.INFO, "New rect: %s" % [rect])


func tile_map_set_cell(tile_hovered : Vector2i, xy : Vector2i, erase := false):
	var rect := tile_map.get_used_rect()
	tile_map.set_cell(0, tile_hovered, 0, xy, -1 if erase else 0)
	
	if not rect.has_point(tile_hovered):
		rect_changed.emit()
