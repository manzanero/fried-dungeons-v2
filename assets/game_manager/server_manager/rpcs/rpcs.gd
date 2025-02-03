class_name Rpcs
extends Node


@rpc("any_peer", "reliable")
func change_flow_state(global_state: FlowController.State, campaign_players: Dictionary):
	var state := global_state
	var campaign_player_data: Dictionary = campaign_players.get(Game.player.slug)
	
	# if player state does not exist or is not 0
	if campaign_player_data and campaign_player_data.get("state"):
		state = campaign_player_data.state
	
	Game.flow.change_flow_state(state)
	
	Debug.print_info_message("Game flow state changed to %s" % state)


@rpc("any_peer", "reliable")
func change_map_slug(old_slug: String, new_slug: String):
	var map: Map = _get_map_by_slug(old_slug); if not map: return
	Game.maps.erase(old_slug)
	Game.maps[new_slug] = map
	map.slug = new_slug


@rpc("any_peer", "reliable")
func change_atlas_texture(map_slug: String, resource_path: String):
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var texture_resource := Game.manager.get_resource(CampaignResource.Type.TEXTURE, resource_path)
	if texture_resource and not texture_resource.resource_loaded:
		await texture_resource.loaded
	map.atlas_texture_resource = texture_resource


@rpc("any_peer", "reliable")
func change_ambient(map_slug: String, 
		light: float, color: Color, master_light: float, master_color: Color):
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	map.master_ambient_light = master_light
	map.master_ambient_color = master_color
	map.ambient_light = light
	map.ambient_color = color
	map.current_ambient_light = light
	map.current_ambient_color = color
	map.current_ambient_light = light


@rpc("any_peer", "reliable")
func set_player_element_control(player_slug: String, element_id: String, control_data := {}):
	if Game.player.slug != player_slug: return
	var level := Game.ui.selected_map.selected_level
	var element := _get_element_by_id(level, element_id); if not element: return
	
	control_data.get_or_add("senses", false)
	element.eye.visible = control_data.senses
	control_data.get_or_add("movement", false)
	element.is_selectable = control_data.movement
		
	Game.player.set_element_control(element_id, control_data)


@rpc("any_peer", "reliable")
func clear_player_element_control(player_slug: String, element_id: String):
	if Game.player.slug != player_slug: return
	var level := Game.ui.selected_map.selected_level
	var element := _get_element_by_id(level, element_id); if not element: return
	
	element.eye.visible = false
	element.is_selectable = false
	
	Game.player.elements.erase(element_id)
#
	Debug.print_info_message("Player \"%s\" clear control data of \"%s\"" % [player_slug, element_id])


@rpc("any_peer", "reliable")
func create_player_signal(map_slug: String, level_index: int, position_2d: Vector2, color: Color):
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	if Game.campaign.is_master or level.is_watched(position_2d):
	#if Game.campaign.is_master or multiplayer.get_remote_sender_id() == 1 or level.is_watched(position_2d):
		map.instancer.create_player_signal(level, position_2d, color)


@rpc("any_peer", "reliable")
func change_resource(resource_type: String, resource_path: String, resource_data: Dictionary) -> void:
	Game.manager.set_resource(resource_type, resource_path, resource_data)
	Debug.print_info_message("Resource \"%s\" (%s) changed" % [resource_path, resource_type])


#region music

@rpc("any_peer", "reliable")
func load_theme_song(resource_path: String) -> void:
	var sound := Game.manager.get_resource(CampaignResource.Type.SOUND, resource_path)
	if not sound.resource_loaded:
		await sound.loaded
	Debug.print_info_message("Theme song \"%s\" loaded" % [resource_path])


@rpc("any_peer", "reliable")
func play_theme_song(resource_path: String, muted := false) -> void:
	if not resource_path:
		Game.ui.tab_jukebox.audio.stop()
		Debug.print_info_message("Theme song stopped")
		return
		
	var sound := Game.manager.get_resource(CampaignResource.Type.SOUND, resource_path)
	if not sound.resource_loaded:
		await sound.loaded
	
	Game.ui.tab_jukebox.audio.file_path = sound.abspath
	Game.ui.tab_jukebox.set_audio_attributes(sound)
	Game.ui.tab_jukebox.audio.play()
	if muted:
		Game.ui.tab_jukebox.audio.volume_db = linear_to_db(0)
	Debug.print_info_message("Theme song \"%s\" started" % [resource_path])


@rpc("any_peer", "reliable")
func change_theme(new_volumen_level: float, new_pitch: float) -> void:
	Game.ui.tab_jukebox.audio.volume_db = linear_to_db(new_volumen_level)
	Game.ui.tab_jukebox.audio.pitch_scale = new_pitch
	Debug.print_info_message("Theme volume changed to %s%%" % [new_volumen_level * 100])


#endregion

#region building

@rpc("any_peer", "reliable")
func set_cell(map_slug: String, level_index: int, tile: Vector2i, tile_data: Dictionary) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	level.set_cell_data(tile, tile_data)


@rpc("any_peer", "reliable")
func remove_cell(map_slug: String, level_index: int, tile: Vector2i) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	level.remove_cell(tile)


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
		material_index: int, material_seed: int, material_layer: int,
		two_sided := false, is_closed := false) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var wall := _get_wall_by_id(level, id); if not wall: return
	wall.material_index = material_index
	wall.material_seed = material_seed
	wall.material_layer = material_layer
	wall.two_sided = two_sided
	wall.is_closed = is_closed
	Debug.print_info_message("Wall \"%s\" changed" % wall.id)


#endregion

#region instancing

@rpc("any_peer", "reliable")
func create_entity(map_slug: String, level_index: int, id: String, position_2d: Vector2, 
		properties_values := {}, rotation_y := 0.0, flipped := false) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var entity := map.instancer.create_entity(level, id, position_2d,
			properties_values, rotation_y, flipped)
	Debug.print_info_message("Entity \"%s\" created" % entity.id)


@rpc("any_peer", "reliable")
func create_light(map_slug: String, level_index: int, id: String, position_2d: Vector2, 
		properties_values := {}, rotation_y := 0.0, flipped := false) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var light := map.instancer.create_light(level, id, position_2d,
			properties_values, rotation_y, flipped)
	Debug.print_info_message("Light \"%s\" created" % light.id)


@rpc("any_peer", "reliable")
func create_prop(map_slug: String, level_index: int, id: String, position_2d: Vector2,
		properties_values := {}, rotation_y := 0.0, flipped := false) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var shape := map.instancer.create_prop(level, id, position_2d, 
			properties_values, rotation_y, flipped)
	Debug.print_info_message("Shape \"%s\" created" % shape.id)


@rpc("any_peer", "reliable")
func set_element_target(map_slug: String, level_index: int, id: String, 
		target_position: Vector3, target_rotation: Vector3) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var element := _get_element_by_id(level, id); if not element: return
	element.target_position = target_position
	element.rotation = target_rotation
	element.is_moving_to_target = true
	var mid = multiplayer.get_remote_sender_id()
	element.set_multiplayer_authority(mid)
	Debug.print_debug_message("Element \"%s\" has new target position" % [element.id])


@rpc("any_peer", "reliable")
func set_element_position(map_slug: String, level_index: int, id: String, 
		position_3d: Vector3, rotation_y := 0.0, flipped := false) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var element := _get_element_by_id(level, id); if not element: return
	element.target_position = position_3d
	element.global_position = position_3d
	element.rotation.y = rotation_y
	element.flipped = flipped
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
func change_element_properties(map_slug: String, level_index: int, id: String, 
		property_values: Dictionary) -> void:
	var map: Map = _get_map_by_slug(map_slug); if not map: return
	var level: Level = _get_level_by_index(map, level_index); if not level: return
	var element := _get_element_by_id(level, id); if not element: return
	match element.type:
		"light": property_values = Light.parse_raw_property_values(property_values)
		"entity": property_values = Entity.parse_raw_property_values(property_values)
		"prop": property_values = Shape.parse_raw_property_values(property_values)
	element.set_property_values(property_values)
	Debug.print_info_message("Element \"%s\" changed properties" % [element.id])


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
