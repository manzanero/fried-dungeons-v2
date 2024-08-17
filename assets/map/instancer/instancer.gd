class_name Instancer
extends Node


@export var map: Map


const ENTITY = preload("res://assets/entity/entity.tscn")


func create_entity(position_2d: Vector2, properties := {}, level: Level = null) -> Entity:
	if not level:
		level = map.selected_level
		
	var entity: Entity = ENTITY.instantiate().init(level, position_2d, properties)
	return entity
