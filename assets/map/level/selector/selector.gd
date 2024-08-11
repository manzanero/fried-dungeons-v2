class_name Selector
extends Node3D

@onready var area: MeshInstance3D = $Area
@onready var grid: MeshInstance3D = $Grid
@onready var grid_material: Material = grid.material_override
@onready var vanish_timer: Timer = $VanishTimer
@onready var wall: MeshInstance3D = $Wall
@onready var column: LineRenderer = %Column


var _has_changed := false
var _cached_grid_position := Vector2.ZERO
var _cached_area_position := Vector2.ZERO


func _ready() -> void:
	area.visible = false
	grid.visible = false
	#wall.visible = false
	column.visible = false
	reset_vanish()
	

func reset_vanish():
	vanish_timer.start()
	

func _process(delta: float) -> void:
	if _has_changed:
		_has_changed = false
		reset_vanish()
	
	if vanish_timer.time_left:
		grid.transparency = lerp(grid.transparency, 0.5, 10 * delta)
		column.transparency = lerp(grid.transparency, 0.25, 10 * delta)
	else:
		grid.transparency = lerp(grid.transparency, 1.0, 10 * delta)
		column.transparency = lerp(grid.transparency, 1.0, 10 * delta)


func move_grid_to(new_position: Vector2) -> void:
	if _cached_grid_position == new_position:
		return
	
	_cached_grid_position = new_position
	_has_changed = true
	
	var new_position_3d := Utils.v2_to_v3(new_position)
	grid.position = new_position_3d.floor() + Vector3.UP * 0.05
	grid_material.set_shader_parameter("mouse_position", new_position_3d)


func tiled_move_area_to(new_position_origin: Vector2, new_position_destiny: Vector2) -> void:
	if _cached_area_position == new_position_destiny:
		return
	
	_cached_area_position = new_position_destiny
	_has_changed = true
	
	var new_position_origin_3d := Utils.v2_to_v3(new_position_origin.floor())
	var new_position_destiny_3d := Utils.v2_to_v3(new_position_destiny.floor())
	var center_position := (new_position_origin_3d + new_position_destiny_3d) * 0.5
	var area_size := (new_position_destiny_3d - new_position_origin_3d).abs() + Vector3.ONE
	area.position = center_position + Vector3(0.5, 0.1, 0.5)
	area.scale = area_size


func move_area_to(new_position_origin: Vector2, new_position_destiny: Vector2) -> void:
	if _cached_area_position == new_position_destiny:
		return
	
	_cached_area_position = new_position_destiny
	_has_changed = true
	
	var new_position_origin_3d := Utils.v2_to_v3(new_position_origin)
	var new_position_destiny_3d := Utils.v2_to_v3(new_position_destiny)
	var center_position := (new_position_origin_3d + new_position_destiny_3d) * 0.5
	var area_size := (new_position_destiny_3d - new_position_origin_3d).abs() + Vector3.UP
	area.position = center_position + Vector3(0, 0.1, 0)
	area.scale = area_size
