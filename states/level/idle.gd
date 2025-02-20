class_name LevelIdleState
extends LevelBaseState


func _enter_state(previous_state: String) -> void:
	super._enter_state(previous_state)
	selector.position_2d = Game.NULL_POSITION_2D


func _exit_state(next_state: String) -> void:
	super._exit_state(next_state)
	selector.position_2d = Game.NULL_POSITION_2D


var drag_origin := Vector2.ZERO
var mouse_move := false


func _physics_process_state(_delta: float) -> String:
	if not level.is_selected:
		return Level.State.GO_BACKGROUND
		
	if Input.is_action_pressed("left_click"):
		process_ground_hitted()
		process_ceilling_hitted()
		
		if Input.is_action_pressed("right_click"):
			selector.column.visible = true
			selector.grid.visible = true
			process_change_grid()
			
			map.distance_label.visible = true
			var distance := drag_origin.distance_to(level.position_hovered)
			map.distance_label.text = "%.1f" % distance
			map.distance_label.position = get_viewport().get_mouse_position()
			map.distance_label.position.x -= map.distance_label.size.x
			map.distance_label.position.y += map.distance_label.size.y
			
	if Input.is_action_just_pressed("left_click"):
		drag_origin = level.position_hovered
	if Input.is_action_just_released("left_click"):
		drag_origin = Vector2.ZERO
	if Input.is_action_just_released("right_click"):
		map.distance_label.visible = false
	
	process_element_selection()
	process_element_movement()
	process_entity_follow()
		
	if Input.is_action_just_pressed("left_click"):
		selector.position_2d = level.position_hovered
		if is_instance_valid(level.element_selected):
			selector.position_2d = level.element_selected.position_2d
	
	_process_delete()
	
	return Level.State.KEEP


func _process_delete() -> void:
	if not Game.player_is_master or not Game.ui.scene_tab_has_focus:
		return
		
	# Delete without ask
	if Input.is_action_just_pressed("force_delete"):
		if is_instance_valid(level.element_selected):
			level.element_selected.remove()
			
			Game.server.rpcs.remove_element.rpc(map.slug, level.index, level.element_selected.id)
			
	elif Input.is_action_just_pressed("delete"):
		if is_instance_valid(level.element_selected):
			Game.ui.mouse_blocker.visible = true
			Game.ui.delete_element_window.visible = true
			Game.ui.delete_element_window.element_selected = level.element_selected
			
			var response = await Game.ui.delete_element_window.response
			if response:
				level.element_selected.remove()
				Game.server.rpcs.remove_element.rpc(map.slug, level.index, level.element_selected.id)


func _input(event: InputEvent):
	if not is_current_state():
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			if level.is_ground_hovered:
				var color := Game.master.color if Game.player_is_master else Game.player.color
				map.instancer.create_player_signal(level, level.position_hovered, color)
				
				Game.server.rpcs.create_player_signal.rpc(map.slug, level.index, 
						level.position_hovered, color)
	
	if event is InputEventMouseMotion:
		mouse_move = true
