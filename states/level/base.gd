class_name LevelBaseState
extends StateNode

var level: Level
var map: Map
var selector: Selector


func _enter_state(previous_state: String) -> void:
	level = get_target()
	map = level.map
	selector = level.selector
	level.select(null)
	Debug.print_debug_message("Level %s of map \"%s\" leaved state: %s" % [level.index, map.slug, previous_state])


func _exit_state(next_state: String) -> void:
	Debug.print_info_message("Level %s of map \"%s\" entering state: %s" % [level.index, map.slug, next_state])


func process_change_grid() -> void:
	if not Game.ui.scene_tab_has_focus:
		return
		
	selector.move_grid_to(level.position_hovered)


func process_change_column(snapping := Game.SNAPPING_QUARTER) -> void:
	if not Game.ui.scene_tab_has_focus:
		return
		
	var point_position := level.position_hovered
	if not Input.is_key_pressed(KEY_ALT):
		point_position = point_position.snappedf(snapping)
		
	selector.column.position = Utils.v2_to_v3(point_position)


func process_wall_selection():
	if not Game.ui.scene_tab_has_focus or Game.handled_input:
		return
	
	if not Input.is_action_just_pressed("left_click"):
		return

	var hit_info := Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, Game.wall_ray)
	if hit_info:
		var wall_hitted := hit_info["collider"].get_parent() as Wall
		level.select(wall_hitted)

		Game.handled_input = true
				
	elif is_instance_valid(level.selected_wall):
		level.selected_wall.is_selected = false
		level.selected_wall = null


func process_element_selection():
	if not Game.ui.scene_tab_has_focus or Game.handled_input:
		return
	
	if not Input.is_action_just_pressed("left_click"):
		return
	
	var hit_info := Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, Game.selector_ray)
	if hit_info:
		var collider = hit_info["collider"]
		while not collider is Element:
			collider = collider.get_parent()
		
		var element_hitted: Element = collider
		level.select(element_hitted)
		Game.handled_input = true
		
		Debug.print_debug_message("Element hitted \"%s\"" % element_hitted.id)
		
	elif is_instance_valid(level.element_selected): 
		level.element_selected.is_selected = false
		level.element_selected = null


func process_element_movement():
	if not level.element_selected:
		return
	if not level.element_selected.is_selected:
		return
		
	if Input.is_action_just_released("left_click"):
		level.element_selected.is_dragged = false
		level.drag_offset = Vector2.ZERO
	
	if not Game.ui.scene_tab_has_focus:
		return
	
	if not Game.campaign.is_master and Game.flow.is_paused:
		return
	
	if Input.is_action_just_pressed("left_click"):
		level.element_selected.is_dragged = true
		if level.element_selected.is_ceiling_element:
			level.drag_offset = level.exact_ceilling_hovered - level.element_selected.position_2d
		else:
			level.drag_offset = level.exact_position_hovered - level.element_selected.position_2d
		

func process_entity_follow():
	if not level.element_selected:
		return
		
	#if Input.is_action_just_pressed("shift_left_click"):
		#level.follower_entity = level.element_selected
		#level.element_selected = null
		#
		##if level.follower_entity:
			##map.camera.target_position.global_position = level.follower_entity.global_position + 0.5 * Vector3.UP
			##map.camera.focus.position = level.follower_entity.global_position + 0.5 * Vector3.UP
			##map.camera.eyes.position.z = 0


func process_ground_hitted():
	level.is_ground_hovered = false

	var hit_info = Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, Game.ground_ray)
	if hit_info:
		var hit_position: Vector3 = hit_info["position"]
		level.exact_position_hovered = Utils.v3_to_v2(hit_position)
		level.position_hovered = level.exact_position_hovered.snappedf(Game.U)
		level.tile_hovered = Utils.v2_to_v2i(level.position_hovered)
		level.is_ground_hovered = true


func process_ceilling_hitted():
	var hit_info = Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, Game.ceilling_ray)
	if hit_info:
		var hit_position = hit_info["position"]
		level.exact_ceilling_hovered = Utils.v3_to_v2(hit_position)
		level.ceilling_hovered = level.exact_ceilling_hovered.snappedf(Game.U)
