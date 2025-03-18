class_name Map
extends Node3D


signal master_view_enabled(value: bool)
signal darkvision_enabled(value: bool)
@warning_ignore("unused_signal") signal label_vision_enabled(value: bool)  
signal map_visibility_changed(value: float)

const DEFAULT_ATLAS_TEXTURE := preload("res://user/defaults/atlas/default.png")


@export var tab_scene: TabScene

@export var loader: Loader
@export var instancer: Instancer
@export var levels_parent: Node3D
@export var camera: Camera

var label := "Untitled"
var slug := "untitled"
var description := ""

var is_selected: bool :
	get: return Game.ui.selected_map == self
	
var levels := {}
var selected_level: Level

var ambient_light := 0.0
var ambient_color := Color.WHITE
var master_ambient_light := 0.25
var master_ambient_color := Color.WHITE
var override_ambient_light := true
var override_ambient_color := false

var is_master_view := false :
	set(value):
		is_master_view = value
		RenderingServer.global_shader_parameter_set("is_master_view", value)
		master_view_enabled.emit(value)

var is_darkvision_view := false :
	set(value):
		is_darkvision_view = value
		if is_master_view:
			current_ambient_light = master_ambient_light if override_ambient_light else ambient_light
		else:
			current_ambient_light = ambient_light
			
		RenderingServer.global_shader_parameter_set("is_darkvision_view", value)
		darkvision_enabled.emit(value)
		
var current_ambient_light := 0.0 :
	set(value):
		current_ambient_light = value
		RenderingServer.global_shader_parameter_set("has_ambient_light", current_ambient_light > 0.001)
		environment.ambient_light_color = current_ambient_color * current_ambient_light
		
var current_ambient_color := Color.WHITE :
	set(value):
		current_ambient_color = value
		environment.ambient_light_color = current_ambient_color * current_ambient_light
		sky_material.sky_top_color = sky_top_color * current_ambient_color
		
var visibility := 1.0 :
	set(value):
		visibility = value
		map_visibility_changed.emit(value)

var atlas_texture: Texture2D = DEFAULT_ATLAS_TEXTURE :
	set(value):
		atlas_texture = value if value else DEFAULT_ATLAS_TEXTURE
		RenderingServer.global_shader_parameter_set("wall_atlas", atlas_texture)
		for level: Level in levels.values():
			var tile_map := level.floor_2d.tile_map
			var source: TileSetAtlasSource = tile_map.tile_set.get_source(0)
			source.texture = atlas_texture

var atlas_texture_resource: CampaignResource :
	set(value):
		if atlas_texture_resource:
			atlas_texture_resource.resource_changed.disconnect(_on_atlas_texture_resource_changed)
		atlas_texture_resource = value
		if atlas_texture_resource:
			atlas_texture_resource.resource_changed.connect(_on_atlas_texture_resource_changed)
			_on_atlas_texture_resource_changed()
		else:
			atlas_texture = null

func _on_atlas_texture_resource_changed():
	if not atlas_texture_resource.resource_loaded:
		await atlas_texture_resource.loaded
	atlas_texture = Utils.png_to_atlas(atlas_texture_resource.abspath)
	Game.ui.tab_builder.reset()


@onready var distance_label: Label = %DistanceLabel

@onready var world_environment: WorldEnvironment = %WorldEnvironment
@onready var environment := world_environment.environment
@onready var sky := environment.sky
@onready var sky_material: ProceduralSkyMaterial = sky.sky_material
@onready var sky_top_color := sky_material.sky_top_color
#@onready var sky_horizon_color := sky_material.sky_horizon_color


func _ready():
	is_master_view = Game.campaign.is_master
	if is_master_view:
		current_ambient_light = master_ambient_light if override_ambient_light else ambient_light
		current_ambient_color = master_ambient_color if override_ambient_color else ambient_color


#region Serializing

func json() -> Dictionary:
	var levels_data := {}
	for level: Level in levels_parent.get_children():
		levels_data[level.index] = level.json()
	
	return {
		"label": label,
		"description": description,
		"levels": levels_data,
		#"camera": {
			#"position": Utils.v3_to_a3(camera.position_3d),
			#"rotation": Utils.v3_to_a3(camera.rotation_3d),
			#"zoom": snappedf(camera.zoom, 0.001),
		#},
		"settings": {
			"atlas_texture": atlas_texture_resource.path if atlas_texture_resource else "",
			"ambient_light": ambient_light,
			"ambient_color": Utils.color_to_html_color(ambient_color),
			"override_ambient_light": override_ambient_light,
			"master_ambient_light": master_ambient_light,
			"override_ambient_color": override_ambient_color,
			"master_ambient_color": Utils.color_to_html_color(master_ambient_color),
			"visibility": visibility,
		},
	}

#endregion
