class_name LevelBaseState
extends StateNode


var level: Level
var map: Map
var selector: Selector

var level_ray := PhysicsRayQueryParameters3D.new()


func _enter_state(previous_state: String) -> void:
	level = get_target()
	map = level.map
	selector = level.selector
	select(null)
	Debug.print_message(Debug.DEBUG, "Level leaving state: %s" % previous_state)


func _exit_state(next_state: String) -> void:
	Game.ui.state_label_value.text = next_state
	Debug.print_message(Debug.INFO, "Level entering state: %s" % next_state)


func process_wall_selection():
	if not Input.is_action_just_pressed("left_click") or Game.handled_input:
		return
		
	if not Game.ui.is_mouse_over_map_tab:
		return

	var hit_info = Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, level_ray, Game.WALL_BITMASK)
	if hit_info:
		var wall_hitted := hit_info["collider"].get_parent() as Wall
		select(wall_hitted)

		Game.handled_input = true
				
	elif is_instance_valid(level.selected_wall):
		level.selected_wall.is_selected = false
		level.selected_wall = null
	

func process_light_selection():
	if not Input.is_action_just_pressed("left_click") or Game.handled_input:
		return
		
	if not Game.ui.is_mouse_over_map_tab:
		return
		
	var hit_info = Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, level_ray, Game.LIGHT_BITMASK)
	if hit_info:
		var light_hitted := hit_info["collider"].get_parent() as Light
		select(light_hitted)
		
		Game.handled_input = true

	elif is_instance_valid(level.selected_light):
		level.selected_light.is_selected = false
		level.selected_light = null


func process_light_movement():
	if not level.selected_light:
		return
		
	if Input.is_action_just_pressed("left_click") and Game.ui.is_mouse_over_map_tab:
		level.selected_light.is_editing = true
		
	elif Input.is_action_just_released("left_click"):
		level.selected_light.is_editing = false


func process_entity_selection():
	if not Input.is_action_just_pressed("left_click") or Game.handled_input:
		return
		
	if not Game.ui.is_mouse_over_map_tab:
		return
	
	var hit_info = Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, level_ray, Game.SELECTOR_BITMASK)
	if hit_info:
		var entity_hitted := hit_info["collider"].get_parent() as Entity
		select(entity_hitted)
		
		Game.handled_input = true
	
	elif is_instance_valid(level.selected_entity): 
		level.selected_entity.is_selected = false
		level.selected_entity = null


func process_entity_movement():
	if not level.selected_entity:
		return
		
	if Input.is_action_just_pressed("left_click") and Game.ui.is_mouse_over_map_tab:
		level.selected_entity.is_editing = true
	elif Input.is_action_just_released("left_click"):
		level.selected_entity.is_editing = false


func process_entity_follow():
	if not level.selected_entity:
		return
		
	if Input.is_action_just_pressed("shift_left_click"):
		level.follower_entity = level.selected_entity
		level.selected_entity = null


func process_ground_hitted():
	level.is_ground_hovered = false

	var hit_info = Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, level_ray, Game.GROUND_BITMASK)
	if hit_info:
		var hit_position = hit_info["position"]
		level.position_hovered = Utils.v3_to_v2(hit_position.snapped(Game.VOXEL))
		level.tile_hovered = Utils.v2_to_v2i(level.position_hovered)
		level.is_ground_hovered = true


func process_ceilling_hitted():
	var hit_info = Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, level_ray, Game.CEILLING_BITMASK)
	if hit_info:
		var hit_position = hit_info["position"]
		level.ceilling_hovered = Utils.v3_to_v2(hit_position.snapped(Game.VOXEL))
		

func select(thing):
	if thing is Light:
		thing.is_selected = true
		level.selected_light = thing
		for light in level.lights_parent.get_children():
			if light != thing:
				light.is_selected = false
	else:
		level.selected_light = null
		for light in level.lights_parent.get_children():
			light.is_selected = false

	if thing is Entity:
		thing.is_selected = true
		level.selected_entity = thing
		for entity: Entity in level.entities_parent.get_children():
			if entity != thing:
				entity.is_selected = false
		
	else:
		level.selected_entity = null
		for entity in level.entities_parent.get_children():
			entity.is_selected = false
				
			
	if thing is Wall:
		thing.is_selected = true
		level.selected_wall = thing
		for wall in level.walls_parent.get_children():
			if wall != thing:
				wall.is_selected = false
		
	else:
		level.selected_wall = null
		for wall in level.walls_parent.get_children():
			wall.is_selected = false
