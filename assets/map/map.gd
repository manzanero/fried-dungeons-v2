class_name Map
extends Node3D


#static var SCENE := preload("res://assets/map/map.tscn")

const DEFAULT_ATLAS_TEXTURE := preload("res://user/defaults/atlas/default.png")


signal master_view_enabled(value : bool)


var levels := {}


@export var loader: Loader
@export var instancer: Instancer
@export var levels_parent: Node3D
@export var camera: Camera

@export var label := "Untitled"
@export var slug := "untitled"
@export var ambient_light := 0.0
@export var ambient_color := Color.WHITE
@export var master_ambient_light := 0.25
@export var master_ambient_color := Color.WHITE
@export var override_ambient_light := true
@export var override_ambient_color := false

@export var is_master_view := false :
	set(value):
		is_master_view = value
		RenderingServer.global_shader_parameter_set("is_master_view", value)
		master_view_enabled.emit(value)
		
@export var current_ambient_light := 0.0 :
	set(value):
		current_ambient_light = value
		RenderingServer.global_shader_parameter_set("has_ambient_light", value > 0.001)
		if is_inside_tree():
			environment.ambient_light_color = current_ambient_color * current_ambient_light

@export var current_ambient_color := Color.WHITE :
	set(value):
		current_ambient_color = value
		if is_inside_tree():
			environment.ambient_light_color = current_ambient_color * current_ambient_light


#var cells := {}
var selected_level: Level

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
	

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var environment := world_environment.environment as Environment
@onready var sky := environment.sky as Sky

@onready var canvas_layer := $CanvasLayer as CanvasLayer
@onready var points_parent := %Points as Control
@onready var point_options := %PointOptions as Control
@onready var add_after_button := %AddAfter as Button
@onready var add_before_button := %AddBefore as Button
@onready var delete_button := %DeleteButton as Button
@onready var break_button := %BreakButton as Button


func _ready():
	add_after_button.button_down.connect(_on_add_after_button_down)
	add_after_button.button_up.connect(_on_add_after_button_up)
	add_after_button.gui_input.connect(_on_gui_input)
	add_after_button.mouse_exited.connect(_on_mouse_exited)
	add_before_button.button_down.connect(_on_add_before_button_down)
	add_before_button.button_up.connect(_on_add_before_button_up)
	add_before_button.gui_input.connect(_on_gui_input)
	add_before_button.mouse_exited.connect(_on_mouse_exited)
	delete_button.button_down.connect(_on_delete_button_down)
	delete_button.gui_input.connect(_on_gui_input)
	delete_button.mouse_exited.connect(_on_mouse_exited)
	break_button.button_down.connect(_on_break_button_down)
	break_button.gui_input.connect(_on_gui_input)
	break_button.mouse_exited.connect(_on_mouse_exited)
	
	point_options.visible = false
	
	# player type settings
	is_master_view = Game.campaign.is_master
	current_ambient_light = master_ambient_light if Game.campaign.is_master else ambient_light
	camera.allow_fp = Game.campaign.is_master

func init_test_data():
	loader.load_donjon_json_file("res://resources/maps/small/small_alt.json")
	#loader.load_donjon_json_file("res://resources/maps/medium/medium.json")


#########
# walls #
#########

func _on_add_after_button_down():
	var wall := selected_level.selected_wall
	var point := wall.selected_point
	var new_point = wall.add_point(selected_level.position_hovered, point.index + 1)
	
	Game.server.rpcs.set_wall_points.rpc(wall.map.slug, wall.level.index, wall.id, wall.points_position_2d)
	
	wall.edit_point(new_point)
	Game.handled_input = true

	
func _on_add_after_button_up():
	var wall := selected_level.selected_wall
	var new_point = wall.edited_point
	wall.select_point(new_point)
	wall.edit_point(null)
	Game.handled_input = true


func _on_add_before_button_down():
	var wall := selected_level.selected_wall
	var point := wall.selected_point
	var new_point = wall.add_point(selected_level.position_hovered, point.index)
	
	Game.server.rpcs.set_wall_points.rpc(wall.map.slug, wall.level.index, wall.id, wall.points_position_2d)
	
	wall.edit_point(new_point)
	Game.handled_input = true

	
func _on_add_before_button_up():
	var wall := selected_level.selected_wall
	var new_point = wall.edited_point
	wall.select_point(new_point)
	wall.edit_point(null)
	Game.handled_input = true


func _on_delete_button_down():
	var wall := selected_level.selected_wall
	wall.remove_point(wall.selected_point)
	wall.select_point(null)
	Game.handled_input = true
	

func _on_break_button_down():
	var wall := selected_level.selected_wall
	wall.break_point(wall.selected_point)
	wall.select_point(null)
	Game.handled_input = true
	
	
func _on_gui_input(_event: InputEvent):
	Game.handled_input = true
	
	
func _on_mouse_exited():
	Game.ui.selected_scene_tab.cursor_control.visible = true


###############
# Serializing #
###############

func json() -> Dictionary:
	var levels_data := {}
	for level: Level in levels_parent.get_children():
		levels_data[level.index] = level.json()
	
	return {
		"label": label,
		"levels": levels_data,
		"settings": {
			"atlas_texture": atlas_texture_resource.path if atlas_texture_resource else "",
			"ambient_light": ambient_light,
			"ambient_color": Utils.color_to_html_color(ambient_color),
			"master_ambient_light": master_ambient_light,
			"master_ambient_color": Utils.color_to_html_color(master_ambient_color),
			"override_ambient_light": override_ambient_light,
			"override_ambient_color": override_ambient_color,
		},
	}
