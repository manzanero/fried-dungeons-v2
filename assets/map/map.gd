class_name Map
extends Node3D


var label := "none"
var cells := {}
var selected_level : Level

@export var ambient_color := Color.WHITE :
	set(value):
		ambient_color = value
		environment.ambient_light_color = ambient_color * ambient_light
		
@export var ambient_light := 0.0 :
	set(value):
		ambient_light = value
		environment.ambient_light_color = ambient_color * ambient_light

@onready var loader := $Loader as Loader
@onready var levels_parent := $Levels as Node3D
@onready var camera := $Camera as Camera
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
	Game.camera = camera

	#DebugMenu.style = DebugMenu.Style.HIDDEN
	DebugMenu.style = DebugMenu.Style.VISIBLE_COMPACT
#	DebugMenu.style = DebugMenu.Style.VISIBLE_DETAILED
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	#DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	add_after_button.button_down.connect(_on_add_after_button_down)
	add_after_button.button_up.connect(_on_add_after_button_up)
	add_before_button.button_down.connect(_on_add_before_button_down)
	add_before_button.button_up.connect(_on_add_before_button_up)
	delete_button.button_down.connect(_on_delete_button_down)
	break_button.button_down.connect(_on_break_button_down)
	
	point_options.visible = false
	
	init_test_data()


func init_test_data():
	loader.load_donjon_json_file("res://resources/maps/small/small.json")
	
	#var level := Game.level_scene.instantiate().init(self) as Level
	#
	#var wall := Game.wall_scene.instantiate().init(level) as Wall
	#wall.add_point(Vector2(0, 2))
	#wall.add_point(Vector2(0, 0))
	#wall.add_point(Vector2(6, 0))
	#wall.add_point(Vector2(6, 2))
	##wall.is_edit_mode = true
	#
	#var wall2 := Game.wall_scene.instantiate().init(level) as Wall
	#wall2.add_point(Vector2(0, 3))
	#wall2.add_point(Vector2(0, 4))
	#wall2.add_point(Vector2(6, 4))
	#wall2.add_point(Vector2(6, 3))
	##wall2.is_edit_mode = true
	#
	##light.position = Vector3(3, 1, 3)


func _on_add_after_button_down():
	var wall := selected_level.selected_wall
	var point := wall.selected_point
	var new_point = wall.add_point(selected_level.position_hovered, point.index + 1)
	wall.edit_point(new_point)

	
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

	
func _on_add_before_button_up():
	var wall := selected_level.selected_wall
	var new_point = wall.edited_point
	wall.select_point(new_point)
	wall.edit_point(null)


func _on_delete_button_down():
	var wall := selected_level.selected_wall
	wall.remove_point(wall.selected_point)
	wall.select_point(null)
	

func _on_break_button_down():
	var wall := selected_level.selected_wall
	wall.break_point(wall.selected_point)
	wall.select_point(null)
	
	
#########
# input #
#########

func _input(event):
	if event is InputEventKey:
		if event.is_pressed():
			if event.keycode == KEY_F4:
				if DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
				else:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
					
			if event.keycode == KEY_F5:
				get_tree().reload_current_scene()
	
	Game.handled_input = true


func _unhandled_input(event):
	Game.handled_input = false
