extends Node

const PIXEL_SIZE := 0.0625
const PIXEL := Vector2.ONE * PIXEL_SIZE
const SNAPPING_HALF := PIXEL * 8
const SNAPPING_QUARTER := PIXEL * 4

const MAX_LIGHTS := 32

const GROUND_LAYER := 1
const WALL_LAYER := 2
const CEILLING_LAYER := 3
const LIGHT_LAYER := 4
const ENTITY_LAYER := 5
const OBJECT_LAYER := 6

var GROUND_BITMASK := Utils.get_bitmask(Game.GROUND_LAYER)
var WALL_BITMASK := Utils.get_bitmask(Game.WALL_LAYER)
var CEILLING_BITMASK := Utils.get_bitmask(Game.CEILLING_LAYER)
var LIGHT_BITMASK := Utils.get_bitmask(Game.LIGHT_LAYER)
var ENTITY_BITMASK := Utils.get_bitmask(Game.ENTITY_LAYER)
var OBJECT_BITMASK := Utils.get_bitmask(Game.OBJECT_LAYER)

var level_scene = load("res://assets/map/level/level.tscn") as PackedScene
var wall_scene = load("res://assets/map/level/wall/wall.tscn") as PackedScene
var wall_point_scene = load("res://assets/map/level/wall/wall_point/wall_point.tscn") as PackedScene
var light_scene = load("res://assets/light/light.tscn") as PackedScene
var entity_scene = load("res://assets/entity/entity.tscn") as PackedScene


var camera : Camera
var handled_input : bool
