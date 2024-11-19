extends Node


var master: Player = Player.new("Master", "", Color.WHITE)
var player: Player
var campaign: Campaign

var manager: GameManager
var server: ServerManager
var flow: FlowController
var preloader: ResourcePreloader
var audio: Audio
var ui: UI

var maps := {}


# Variables

var world_seed := randi_range(0, 999999)
var handled_input : bool
var radian_friendly_tick := 0
var wave_global := 0.0


# Constants

const U := 1.0 / 16.0
const PIXEL := Vector2.ONE * U
const VOXEL := Vector3.ONE * U
const SNAPPING_HALF := U * 8
const SNAPPING_QUARTER := U * 4
const PIXEL_SNAPPING_HALF := PIXEL * 8
const PIXEL_SNAPPING_QUARTER := PIXEL * 4
const PIXEL_SNAPPING_HALF_QUARTER := PIXEL * 2
const VOXEL_SNAPPING_HALF := VOXEL * 8
const VOXEL_SNAPPING_QUARTER := VOXEL * 4
const NULL_POSITION_2D := Vector2.ONE * 999999
const NULL_POSITION_3D := Vector3.ONE * 999999
const NULL_TILE := Vector2i.ONE * 999999

const MAX_LIGHTS := 60  # TODO: check if can be higher

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

const level_scene := preload("res://assets/map/level/level.tscn")
const wall_point_scene := preload("res://assets/map/level/wall/wall_point/wall_point.tscn")
