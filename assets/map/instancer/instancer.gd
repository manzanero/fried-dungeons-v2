class_name Instancer
extends Node


@export var map: Map


const WALL = preload("res://assets/map/level/wall/wall.tscn")
const ENTITY = preload("res://assets/element/entity/entity.tscn")
const LIGHT = preload("res://assets/element/light/light.tscn")
const PROP = preload("res://assets/element/prop/prop.tscn")
const PLAYER_SIGNAL = preload("res://assets/player_signal/player_signal.tscn")


func create_wall(level: Level, id: String, points_position_2d: Array[Vector2], 
		index := 0, wall_seed := 0, wall_layer := 1, two_sided := false , is_closed := false ) -> Wall:
	var wall: Wall = WALL.instantiate().init(
		level, id, index, wall_seed, wall_layer, two_sided, is_closed)
	wall.points_position_2d = points_position_2d
	level.walls[id] = wall
	return wall


func create_element(type: String, level: Level, id: String, position_2d: Vector2,
		properties := {}, rotation_y := 0.0, flipped := false, 
		is_preview := false, is_favourite := false) -> Element:
	var element: Element
	match type:
		"entity": 
			element = ENTITY.instantiate().init(level, id, position_2d, 
			properties, rotation_y, flipped, is_preview, is_favourite)
		"light": 
			element = LIGHT.instantiate().init(level, id, position_2d, 
			properties, rotation_y, flipped, is_preview, is_favourite)
		"prop", "shape": 
			element = PROP.instantiate().init(level, id, position_2d, 
			properties, rotation_y, flipped, is_preview, is_favourite)
	
	level.elements[id] = element
	if not is_preview:
		Game.ui.tab_elements.add_element(element)
	
	Debug.print_info_message(element.get_class() + " \"%s\" created" % element.id)
	
	return element
		

func create_entity(level: Level, id: String, position_2d: Vector2,
		properties := {}, rotation_y := 0.0, flipped := false, 
		is_preview := false, is_favourite := false) -> Entity:
	return create_element("entity", 
			level, id, position_2d, properties, rotation_y, flipped, is_preview, is_favourite)

func create_light(level: Level, id: String, position_2d: Vector2,
		properties := {}, rotation_y := 0.0, flipped := false, 
		is_preview := false, is_favourite := false) -> Light:
	return create_element("light", 
			level, id, position_2d, properties, rotation_y, flipped, is_preview, is_favourite)

func create_prop(level: Level, id: String, position_2d: Vector2,
		properties := {}, rotation_y := 0.0, flipped := false, 
		is_preview := false, is_favourite := false) -> Prop:
	return create_element("prop", 
			level, id, position_2d, properties, rotation_y, flipped, is_preview, is_favourite)

func create_player_signal(level: Level, position_2d: Vector2, color: Color) -> PlayerSignal:
	return PLAYER_SIGNAL.instantiate().init(level, position_2d, color)
