class_name LevelIdleState
extends LevelBaseState


func _physics_process_state(_delta: float) -> String:
	if Input.is_action_pressed("left_click"):
		process_ground_hitted()
		process_ceilling_hitted()
		
	process_light_selection()
	process_light_movement()
	process_entity_selection()
	process_entity_movement()
	process_entity_follow()
	return ""
