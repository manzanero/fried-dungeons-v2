class_name LevelBaseState
extends StateNode

var level: Level
var map: Map
var selector: Selector

var is_selecting := false
var is_moving := false
var _selection_origin := Game.NULL_POSITION_2D

var prevent_exit := false



func _enter_state(previous_state: String) -> void:
	level = get_target()
	map = level.map
	selector = level.selector
	level.select(null)
	Debug.print_debug_message("Level %s of map \"%s\" leaved state: %s" % [level.index, map.slug, previous_state])


func _exit_state(next_state: String) -> void:
	prevent_exit = false
	Debug.print_info_message("Level %s of map \"%s\" entering state: %s" % [level.index, map.slug, next_state])


func _process_state(_delta: float) -> String:
	if not map.is_selected or not level.is_selected:
		return Level.State.GO_BACKGROUND
		
	if Input.is_action_just_pressed("ui_cancel"):
		Game.modes.reset()
		return Level.State.GO_IDLE
	
	# end with right clik with no movement
	if not Input.is_action_pressed("right_click") and Game.ui.scene_tab_has_focus:
		if not prevent_exit and not mouse_move and Input.is_action_just_released("right_click"):
			Game.modes.reset()
			return Level.State.GO_IDLE
		mouse_move = false
	
	return Level.State.KEEP


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
	if is_moving:
		return
		
	if Input.is_action_just_pressed("left_click") and Game.ui.scene_tab_has_focus:
		var element_hitted := get_element_hitted()
		Game.ui.tab_properties.element_selected = element_hitted
			
		if element_hitted and not element_hitted.is_selected and not Input.is_key_pressed(KEY_CTRL):
			for element: Element in level.elements_selected.values():
				element.is_selected = false
		
		if element_hitted:
			element_hitted.is_selected = true
			is_moving = true
			_selection_origin = level.position_hovered
			return
		
		is_selecting = true
		_selection_origin = level.position_hovered
		selector.position_2d = Game.NULL_POSITION_2D
		selector.move_grid_to(Game.NULL_POSITION_2D)
		
		if not Input.is_key_pressed(KEY_CTRL):
			for element: Element in level.elements_selected.values():
				if element_hitted != element:
					element.is_selected = false
		
	if is_selecting and Game.ui.scene_tab_has_focus:
		selector.area.visible = true
		selector.move_area_to(_selection_origin, level.position_hovered)
		
	if Input.is_action_just_released("left_click") and is_selecting:
		selector.area.visible = false
		is_selecting = false
		
		var selection_rect := Rect2(_selection_origin, level.position_hovered - _selection_origin).abs()
		var elements := level.elements.values()
		for element: Element in elements:
			if selection_rect.has_point(element.position_2d):
				element.is_selected = element.is_selectable
		#if Game.player_is_master and not Game.master_is_player:
			#for element: Element in elements:
				#if selection_rect.has_point(element.position_2d):
					#element.is_selected = true
		#else:
			#for element: Element in elements:
				#if selection_rect.has_point(element.position_2d):
					#element.is_selected = element.is_selectable
		

func get_element_hitted() -> Element:
	var hit_info := Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, Game.selector_ray)
	if hit_info:
		var collider = hit_info["collider"]
		while not collider is Element:
			collider = collider.get_parent()
		return collider
	return null
		

func process_element_movement():
	if not is_moving:
		return
		
	if Input.is_action_just_released("left_click"):
		for element: Element in level.elements_selected.values():
			element.is_dragged = false
			element.is_moving_to_target = false
		level.drag_offset = Vector2.ZERO
		is_moving = false
	
	if not Game.ui.is_mouse_over_scene_tab:
		return
	
	if not Game.campaign.is_master and Game.flow.is_paused:
		return
	
	if Input.is_action_just_pressed("left_click"):
		if level.element_selected.is_ceiling_element:
			level.drag_offset = level.exact_ceilling_hovered - level.element_selected.position_2d
		else:
			level.drag_offset = level.exact_position_hovered - level.element_selected.position_2d
			
		for element: Element in level.elements_selected.values():
			element.is_dragged = true
			element.target_offset = element.position - level.element_selected.position
		

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


var mouse_move: bool

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("right_click"):
			mouse_move = true
