extends Node

const PIXEL_SIZE := 0.0625
const PIXEL := Vector2(PIXEL_SIZE, PIXEL_SIZE)

var floor_3d_scene = load("res://asserts/map/floor_3d/floor_3d.tscn") as PackedScene
var wall_scene = load("res://asserts/map/floor_3d/wall/wall.tscn") as PackedScene
var wall_point_scene = load("res://asserts/map/floor_3d/wall/wall_point/wall_point.tscn") as PackedScene


var camera : Camera

