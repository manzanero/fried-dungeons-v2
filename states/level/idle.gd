class_name LevelIdleState
extends LevelBaseState


func _enter_state(previous_state: String) -> void:
	super._enter_state(previous_state)
	selector.position_2d = Game.NULL_POSITION_2D


func _exit_state(next_state: String) -> void:
	super._exit_state(next_state)
	selector.position_2d = Game.NULL_POSITION_2D


func _physics_process_state(_delta: float) -> String:
	if level != Game.ui.selected_map.selected_level:
		return ""
		
	if Input.is_action_pressed("left_click"):
		process_ground_hitted()
		process_ceilling_hitted()
		process_change_grid()
	
	process_element_selection()
	process_element_movement()
	process_entity_follow()
		
	if Input.is_action_just_pressed("left_click"):
		selector.position_2d = level.position_hovered
		if is_instance_valid(level.element_selected):
			selector.position_2d = level.element_selected.position_2d
		
	return ""


func _input(e: InputEvent):
	if not is_current_state():
		return

	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.double_click:
		if level.is_ground_hovered:
			var color := Game.player.color if Game.player else Game.master.color
			map.instancer.create_player_signal(level, level.position_hovered, color)
			
			Game.server.rpcs.create_player_signal.rpc(map.slug, level.index, level.position_hovered, color)
