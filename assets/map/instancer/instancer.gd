class_name Instancer
extends Node


@export var map: Map


const WALL = preload("res://assets/map/level/wall/wall.tscn")
const ENTITY = preload("res://assets/element/entity/entity.tscn")
const LIGHT = preload("res://assets/element/light/light.tscn")
const SHAPE = preload("res://assets/element/shape/shape.tscn")
const PLAYER_SIGNAL = preload("res://assets/player_signal/player_signal.tscn")


func create_wall(level: Level, id: String, points_position_2d: Array[Vector2], 
		index := 0, wall_seed := 0, wall_layer := 1, two_sided := false ) -> Wall:
	var wall: Wall = WALL.instantiate().init(
		level, id, index, wall_seed, wall_layer, two_sided)
	wall.points_position_2d = points_position_2d
	level.walls[id] = wall
	return wall


func create_element(type: String, level: Level, id: String, 
		position_2d: Vector2, properties := {}, rotation := 0.0) -> Element:
	var element: Element
	match type:
		"entity": element = ENTITY.instantiate().init(level, id, position_2d, properties, rotation)
		"light": element = LIGHT.instantiate().init(level, id, position_2d, properties, rotation)
		"shape": element = SHAPE.instantiate().init(level, id, position_2d, properties, rotation)
	level.elements[id] = element
	Game.ui.tab_elements.add_element(element)
	return element

func create_entity(level: Level, id: String, position_2d: Vector2, properties := {}, rotation := 0.0) -> Entity:
	return create_element("entity", level, id, position_2d, properties, rotation)

func create_light(level: Level, id: String, position_2d: Vector2, properties := {}, rotation := 0.0) -> Light:
	return create_element("light", level, id, position_2d, properties, rotation)

func create_shape(level: Level, id: String, position_2d: Vector2, properties := {}, rotation := 0.0) -> Shape:
	return create_element("shape", level, id, position_2d, properties, rotation)

func create_player_signal(level: Level, position_2d: Vector2, color: Color) -> PlayerSignal:
	return PLAYER_SIGNAL.instantiate().init(level, position_2d, color)
