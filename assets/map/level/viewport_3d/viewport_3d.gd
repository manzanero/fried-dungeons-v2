class_name Viewport3D
extends MeshInstance3D


signal rect_changed(new_rect : Rect2)


var rect : Rect2 :
	set(value):
		rect = value
		rect_changed.emit(rect)


@onready var floor_viewport: SubViewport = %FloorViewport
@onready var floor_2d := $FloorViewport/Floor2D as Floor2D
@onready var tile_map := floor_2d.tile_map as TileMap

@onready var refresh_light_timer: Timer = %RefreshLightTimer
@onready var light_viewport: SubViewport = %LightViewport
@onready var camera_3d: Camera3D = %Camera3D


func _ready():
	rect_changed.connect(_on_rect_changed)
	
	# set init state
	rect = tile_map.get_used_rect()
	
	
func _on_rect_changed(new_rect: Rect2):
	if not new_rect:
		return
	
	var tile_size = tile_map.tile_set.tile_size.x
	var rect_position := new_rect.position
	var rect_size := new_rect.size
	
	floor_2d.position = -rect_position * tile_size
	floor_viewport.size = rect_size * tile_size
	position = Vector3(rect_position.x + rect_size.x / 2.0, 0, rect_position.y + rect_size.y / 2.0)
	(mesh as PlaneMesh).size = rect_size
	
	# light viewport
	light_viewport.size = floor_viewport.size / 4
	camera_3d.size = rect_size.x
	camera_3d.position = position + Vector3.UP
	
	light_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	floor_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	# TODO light_sample_2d needs to be updated?

	Debug.print_debug_message("New rect: %s" % [rect])


func tile_map_set_cell(tile_hovered : Vector2i, xy : Vector2i, erase := false):
	tile_map.set_cell(0, tile_hovered, 0, xy, -1 if erase else 0)
	if not rect.has_point(tile_hovered):
		rect = tile_map.get_used_rect()
