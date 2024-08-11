class_name Map
extends Node3D


signal master_view_enabled(value : bool)


@export var is_master := false
@export var camera: Camera

@export var title := "Untitled"
@export var ambient_light := 0.0
@export var ambient_color := Color.WHITE
@export var master_ambient_light := 0.5
@export var master_ambient_color := Color.WHITE

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


var label := "none"
var cells := {}
var selected_level : Level


@onready var loader: Loader = $Loader

@onready var levels_parent := $Levels as Node3D
@onready var world_environment := $WorldEnvironment as WorldEnvironment
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
	DebugMenu.style = DebugMenu.Style.HIDDEN
	#DebugMenu.style = DebugMenu.Style.VISIBLE_COMPACT
#	DebugMenu.style = DebugMenu.Style.VISIBLE_DETAILED
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	#DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	#camera.fps_enabled.connect(_on_camera_fps_enabled)

	add_after_button.button_down.connect(_on_add_after_button_down)
	add_after_button.button_up.connect(_on_add_after_button_up)
	add_before_button.button_down.connect(_on_add_before_button_down)
	add_before_button.button_up.connect(_on_add_before_button_up)
	delete_button.button_down.connect(_on_delete_button_down)
	break_button.button_down.connect(_on_break_button_down)
	
	point_options.visible = false
	
	# player type settings
	is_master_view = is_master
	current_ambient_light = master_ambient_light if is_master else ambient_light
	
	init_test_data()


func init_test_data():
	loader.load_donjon_json_file("res://resources/maps/small/small_alt.json")
	#loader.load_donjon_json_file("res://resources/maps/medium/medium.json")


#func _on_camera_fps_enabled(value: bool):
	#if is_master:
		#is_master_view = true
		#current_ambient_light = ambient_light if value else master_ambient_light
	#else:
		#is_master_view = value
		#current_ambient_light = ambient_light


#########
# walls #
#########

func _on_add_after_button_down():
	var wall := selected_level.selected_wall
	var point := wall.selected_point
	var new_point = wall.add_point(selected_level.position_hovered, point.index + 1)
	wall.edit_point(new_point)
	Game.handled_input = true

	
func _on_add_after_button_up():
	var wall := selected_level.selected_wall
	var new_point = wall.edited_point
	wall.select_point(new_point)
	wall.edit_point(null)


func _on_add_before_button_down():
	var wall := selected_level.selected_wall
	var point := wall.selected_point
	var new_point = wall.add_point(selected_level.position_hovered, point.index)
	wall.edit_point(new_point)
	Game.handled_input = true

	
func _on_add_before_button_up():
	var wall := selected_level.selected_wall
	var new_point = wall.edited_point
	wall.select_point(new_point)
	wall.edit_point(null)


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
