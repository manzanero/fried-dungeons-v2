class_name Instancer
extends Node


@export var map: Map


const WALL = preload("res://assets/map/level/wall/wall.tscn")
const ENTITY = preload("res://assets/entity/entity.tscn")
const LIGHT = preload("res://assets/light/light.tscn")


func create_wall(level: Level, id: String, points_position_2d: Array[Vector2], 
		index := 0, wall_seed := 0, wall_layer := 1, two_sided := false ) -> Wall:
	var wall: Wall = WALL.instantiate().init(
		level, id, index, wall_seed, wall_layer, two_sided)
	wall.points_position_2d = points_position_2d
	level.walls[id] = wall
	return wall


func create_entity(level: Level, id: String, position_2d: Vector2, properties := {}) -> Entity:
	var entity: Entity = ENTITY.instantiate().init(level, id, position_2d, properties)
	level.elements[id] = entity
	Game.ui.tab_elements.add_element(entity)
	entity.property_changed.connect(Game.ui.tab_elements.changed_element.bind(entity).unbind(3))
	entity.tree_exited.connect(Game.ui.tab_elements.remove_element.bind(entity))
	return entity


func create_light(level: Level, id: String, position_2d: Vector2, properties := {}) -> Light:
	var light: Light = LIGHT.instantiate().init(level, id, position_2d, properties)
	level.elements[id] = light
	Game.ui.tab_elements.add_element(light)
	light.property_changed.connect(Game.ui.tab_elements.changed_element.bind(light))
	light.tree_exited.connect(Game.ui.tab_elements.remove_element.bind(light))
	return light
