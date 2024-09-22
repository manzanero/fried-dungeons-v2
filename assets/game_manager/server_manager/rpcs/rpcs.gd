class_name Rpcs
extends Node

#region building

@rpc("any_peer", "reliable")
func build_point(map_slug: String, level_index: int, tile: Vector2i, tile_data: Dictionary) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	level.build_point(tile, tile_data)


@rpc("any_peer", "reliable")
func create_wall(map_slug: String, level_index: int, id: String, points_position_2d: Array[Vector2], 
		material_index: int, material_seed: int, material_layer: int, two_sided := false) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var wall := map.instancer.create_wall(level, id, points_position_2d, 
			material_index, material_seed, material_layer, two_sided)
	wall.points_position_2d = points_position_2d
	wall.material_index = material_index
	wall.material_seed = material_seed
	wall.material_layer = material_layer
	wall.two_sided = two_sided
	Debug.print_info_message("Wall \"%s\" created" % wall.id)


@rpc("any_peer", "reliable")
func divide_wall(map_slug: String, level_index: int, id: String,
		new_ids: Array, new_points_position_2d: Array) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var wall := _get_wall_by_id(level, id); if not wall: return
	remove_wall(map_slug, level_index, id)
	for i in range(new_ids.size()):
		create_wall(map_slug, level_index, new_ids[i], new_points_position_2d[i], 
		wall.material_index, wall.material_seed, wall.material_layer, wall.two_sided)
	Debug.print_info_message("Wall \"%s\" divided into %s" % [wall.id, new_ids])


@rpc("any_peer", "reliable")
func remove_wall(map_slug: String, level_index: int, id: String) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var wall := _get_wall_by_id(level, id); if not wall: return
	wall.remove()
	Debug.print_info_message("Wall \"%s\" removed" % wall.id)


@rpc("any_peer", "reliable")
func set_wall_point(map_slug: String, level_index: int, id: String, 
		index: int, position_2d: Vector2) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var wall := _get_wall_by_id(level, id); if not wall: return
	wall.set_point(wall.points[index], position_2d)
	Debug.print_info_message("Wall \"%s\" setted point %s" % [wall.id, index])


@rpc("any_peer", "reliable")
func set_wall_points(map_slug: String, level_index: int, id: String,
		points_position_2d: PackedVector2Array) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var wall := _get_wall_by_id(level, id); if not wall: return
	wall.points_position_2d = points_position_2d
	Debug.print_info_message("Wall \"%s\" changed" % wall.id)


@rpc("any_peer", "reliable")
func set_wall_properties(map_slug: String, level_index: int, id: String,
		material_index: int, material_seed: int, material_layer: int, two_sided := false ) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var wall := _get_wall_by_id(level, id); if not wall: return
	wall.material_index = material_index
	wall.material_seed = material_seed
	wall.material_layer = material_layer
	wall.two_sided = two_sided
	Debug.print_info_message("Wall \"%s\" changed" % wall.id)

#endregion


#region elements

@rpc("any_peer", "reliable")
func create_entity(map_slug: String, level_index: int, id: String, 
		position_2d: Vector2, properties_values := {}) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var entity := map.instancer.create_entity(level, id, position_2d, properties_values)
	Debug.print_info_message("Entity \"%s\" created" % entity.id)


@rpc("any_peer", "reliable")
func create_light(map_slug: String, level_index: int, id: String, 
		position_2d: Vector2, properties_values := {}) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var light := map.instancer.create_light(level, id, position_2d, properties_values)
	Debug.print_info_message("Light \"%s\" created" % light.id)


@rpc("any_peer", "reliable")
func set_element_target(map_slug: String, level_index: int, id: String, 
		position_3d: Vector3) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var element := _get_element_by_id(level, id); if not element: return
	element.target_position = position_3d
	element.is_moving_to_target = true
	Debug.print_info_message("Element \"%s\" has new target position" % [element.id])


@rpc("any_peer", "reliable")
func set_element_position(map_slug: String, level_index: int, id: String, 
		position_3d: Vector3) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var element := _get_element_by_id(level, id); if not element: return
	element.target_position = position_3d
	element.position = position_3d
	element.is_moving_to_target = false
	Debug.print_info_message("Element \"%s\" has new position" % [element.id])


@rpc("any_peer", "reliable")
func change_element_property(map_slug: String, level_index: int, id: String, 
		property_name: String, new_value: Variant) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var element := _get_element_by_id(level, id); if not element: return
	element.set_property_value(property_name, new_value)
	Debug.print_info_message("Element \"%s\" changed property \"%s\" to value \"%s\"" % [element.id, property_name, new_value])


@rpc("any_peer", "reliable")
func remove_element(map_slug: String, level_index: int, id: String) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var element := _get_element_by_id(level, id); if not element: return
	element.remove()
	Debug.print_info_message("Element \"%s\" (%s) removed" % [element.label, element.id])

#endregion


func _get_map_by_slug(slug: String) -> Map:
	var map: Map = Game.maps.get(slug)
	if not map:
		Debug.print_debug_message("Map \"%s\" not opened" % [slug])
		
	return map

func _get_level_by_index(map: Map, index: int) -> Level:
	var level: Level = map.levels.get(index)
	if not level:
		Debug.print_debug_message("Level \"%s\" not exist" % [index])
		
	return level

func _get_wall_by_id(level: Level, id: String) -> Wall:
	var wall: Wall = level.walls.get(id)
	if not wall:
		Debug.print_debug_message("Wall \"%s\" not exist" % [id])
		
	return wall

func _get_element_by_id(level: Level, id: String) -> Element:
	var element: Element = level.elements.get(id)
	if not element:
		Debug.print_debug_message("Entity \"%s\" not exist" % [id])
		
	return element
