extends Node


var master: Player
var player: Player
var campaign: Campaign
var player_is_master: bool :
	get: return campaign and campaign.is_master
var master_is_player: Player

var manager: GameManager
var server: ServerManager
var flow: FlowController
var modes: ModeController
var preloader: ResourcePreloader
#var audio: Audio
var ui: UI

var blueprints := {}
var resources := {}
var maps := {}

var clipboard: Dictionary = {"type": "none", "items": []}


# Variables

var world_seed := randi_range(0, 999999)
var handled_input: bool
var process_frame: int
var ticks_msec: int
var radian_friendly_tick := 0
var wave_global := 0.0
var control_with_focus: Control
var control_uses_keyboard: bool


# Constants

#region Units
const U := 1.0 / 16.0
const PIXEL := Vector2.ONE * U
const VOXEL := Vector3.ONE * U
const SNAPPING_HALF := U * 8
const SNAPPING_QUARTER := U * 4
const SNAPPING_HALF_QUARTER := U * 2
const PIXEL_SNAPPING_HALF := PIXEL * 8
const PIXEL_SNAPPING_QUARTER := PIXEL * 4
const PIXEL_SNAPPING_HALF_QUARTER := PIXEL * 2
const VOXEL_SNAPPING_HALF := VOXEL * 8
const VOXEL_SNAPPING_QUARTER := VOXEL * 4

const NULL_STRING := "I am Error"
const NULL_POSITION_2D := Vector2.ONE * 999999
const NULL_POSITION_3D := Vector3.ONE * 999999
const NULL_TILE := Vector2i.ONE * 999999

#endregion

#region ui
const TREE_TEXT_OFF_COLOR := Color(0.5, 0.5, 0.5)
const TREE_BUTTON_OFF_COLOR := Color(0.25, 0.25, 0.25)
const WHITE_PIXEL: Texture2D = preload("res://resources/icons/white_pixel.png")

#endregion

#region physics
const MAX_LIGHTS := 60  # TODO: check if can be higher

const ENTITY_LAYER := 18
const LIGHT_LAYER := 19
const PROP_LAYER := 20
const GROUND_LAYER := 25
const WALL_LAYER := 26
const CEILLING_LAYER := 27
const SELECTOR_LAYER := 28

var LIGHT_BITMASK := Utils.get_bitmask(Game.LIGHT_LAYER)
var ENTITY_BITMASK := Utils.get_bitmask(Game.ENTITY_LAYER)
var PROP_BITMASK := Utils.get_bitmask(Game.PROP_LAYER)
var ELEMENT_BITMASK := LIGHT_BITMASK + ENTITY_BITMASK + PROP_BITMASK
var GROUND_BITMASK := Utils.get_bitmask(Game.GROUND_LAYER)
var WALL_BITMASK := Utils.get_bitmask(Game.WALL_LAYER)
var CEILLING_BITMASK := Utils.get_bitmask(Game.CEILLING_LAYER)
var SELECTOR_BITMASK := Utils.get_bitmask(Game.SELECTOR_LAYER)

var ground_ray := Utils.ray(GROUND_BITMASK)
var ceilling_ray := Utils.ray(CEILLING_BITMASK)
var wall_ray := Utils.ray(WALL_BITMASK)
var entity_ray := Utils.ray(ENTITY_BITMASK)
var light_ray := Utils.ray(LIGHT_BITMASK)
var prop_ray := Utils.ray(PROP_BITMASK)
var element_ray := Utils.ray(ELEMENT_BITMASK)
var selector_ray := Utils.ray(SELECTOR_BITMASK)

#endregion

var DEFAULT_INDEX_TEXTURE_ATTRS: Dictionary = {"size": [16, 16], "textures": 64, "frames": 8}
