extends Node


var world_seed := randi_range(0, 999999)
var player_name: String = 'Player'
var player_color: Color = Color.RED
var campaign_name: String = 'My Campaign'
var ui: UI
var handled_input : bool


# Constants

const U := 1.0 / 16.0
const PIXEL := Vector2.ONE * U
const VOXEL := Vector3.ONE * U
const SNAPPING_HALF := U * 8
const SNAPPING_QUARTER := U * 4
const PIXEL_SNAPPING_HALF := PIXEL * 8
const PIXEL_SNAPPING_QUARTER := PIXEL * 4
const VOXEL_SNAPPING_HALF := VOXEL * 8
const VOXEL_SNAPPING_QUARTER := VOXEL * 4

const MAX_LIGHTS := 30

const ENTITY_LAYER := 17
const LIGHT_LAYER := 18
const OBJECT_LAYER := 19
const GROUND_LAYER := 25
const WALL_LAYER := 26
const CEILLING_LAYER := 27
const SELECTOR_LAYER := 28

var ENTITY_BITMASK := Utils.get_bitmask(Game.ENTITY_LAYER)
var LIGHT_BITMASK := Utils.get_bitmask(Game.LIGHT_LAYER)
var OBJECT_BITMASK := Utils.get_bitmask(Game.OBJECT_LAYER)
var GROUND_BITMASK := Utils.get_bitmask(Game.GROUND_LAYER)
var WALL_BITMASK := Utils.get_bitmask(Game.WALL_LAYER)
var CEILLING_BITMASK := Utils.get_bitmask(Game.CEILLING_LAYER)
var SELECTOR_BITMASK := Utils.get_bitmask(Game.SELECTOR_LAYER)

var level_scene = load("res://assets/map/level/level.tscn") as PackedScene
var wall_scene = load("res://assets/map/level/wall/wall.tscn") as PackedScene
var wall_point_scene = load("res://assets/map/level/wall/wall_point/wall_point.tscn") as PackedScene
var light_scene = load("res://assets/light/light.tscn") as PackedScene
var entity_scene = load("res://assets/entity/entity.tscn") as PackedScene
