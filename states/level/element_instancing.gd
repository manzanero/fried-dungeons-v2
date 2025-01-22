class_name LevelElementInstancingState
extends LevelBaseState


enum {
	OMNILIGHT, ENTITY_3D, ENTITY_BILLBOARD, PROP_3D, PROP_DECAL
}


var mode: int
var material_index_selected: int :
	get: return Game.ui.tab_builder.material_index_selected


var _previous_rotation: float
var _previous_properties := {}


func _enter_state(previous_state: String) -> void:
	super(previous_state)
	Game.ui.build_border.visible = true
	selector.grid.visible = true
	selector.column.visible = false
	selector.position_2d = Game.NULL_POSITION_2D


func _exit_state(next_state: String) -> void:
	super(next_state)
	Game.ui.build_border.visible = false
	_previous_properties = {}
	_previous_rotation = 0.0
	if is_instance_valid(level.preview_element):
		level.preview_element.remove()


func _physics_process_state(_delta: float) -> String:
	if not map.is_selected or not level.is_selected:
		return Level.State.GO_BACKGROUND
	
	process_ground_hitted()
	
	if Input.is_action_just_pressed("ui_cancel"):
		Game.modes.reset()
		return Level.State.GO_IDLE
	
	match mode:
		OMNILIGHT:
			process_ceilling_hitted()
			process_change_grid()
			process_instance_light()
		ENTITY_3D:
			process_change_grid()
			process_instance_entity()
		PROP_3D:
			process_change_grid()
			process_instance_shape()
			
	return Level.State.KEEP


func process_instance_entity():
	var entity := level.preview_element
	if not is_instance_valid(entity):
		entity = map.instancer.create_entity(level, Utils.random_string(8, true), 
				selector.position_2d, _previous_properties, _previous_rotation)
		entity.is_preview = true
		select(entity)
		level.preview_element = entity
		
	entity.is_rotated = Input.is_action_pressed("rotate")
	
	if Input.is_action_just_released("left_click") and Game.ui.is_mouse_over_scene_tab:
		_previous_properties = level.preview_element.properties_values
		_previous_rotation = entity.rotation.y
		level.preview_element = null
		
		if Game.ui.is_mouse_over_scene_tab:
			entity.is_rotated = false
			entity.is_preview = false
			
			Debug.print_info_message("Entity \"%s\" created" % entity.id)
		
			Game.server.rpcs.create_entity.rpc(map.slug, level.index, entity.id, 
					entity.position_2d, entity.properties_values, entity.rotation_y)
				
		else:
			entity.remove()
	

func process_instance_light():
	if not is_instance_valid(level.preview_element):
		level.preview_element = map.instancer.create_light(level, Utils.random_string(8, true), 
				selector.position_2d, _previous_properties)
		level.preview_element.is_preview = true
		select(level.preview_element)
	
	if Input.is_action_just_released("left_click") and Game.ui.is_mouse_over_scene_tab:
		var light := level.preview_element
		Debug.print_info_message("Light \"%s\" created" % light.id)
		light.is_preview = false
		Game.server.rpcs.create_light.rpc(map.slug, level.index, light.id, 
				light.position_2d, light.properties_values, light.rotation_y)

		_previous_properties = level.preview_element.properties_values
		level.preview_element = null
	

func process_instance_shape():
	var shape := level.preview_element
	if not is_instance_valid(shape):
		shape = map.instancer.create_shape(level, Utils.random_string(8, true), 
				selector.position_2d, _previous_properties, _previous_rotation)
		shape.is_preview = true
		select(shape)
		level.preview_element = shape
		
	shape.is_rotated = Input.is_action_pressed("rotate")
	
	if Input.is_action_just_released("left_click") and Game.ui.is_mouse_over_scene_tab:
		_previous_properties = level.preview_element.properties_values
		_previous_rotation = shape.rotation.y
		level.preview_element = null
		
		if Game.ui.is_mouse_over_scene_tab:
			shape.is_rotated = false
			shape.is_preview = false
			
			Debug.print_info_message("Shape \"%s\" created" % shape.id)
		
			Game.server.rpcs.create_shape.rpc(map.slug, level.index, shape.id,
					shape.position_2d, shape.properties_values, shape.rotation_y)
				
		else:
			shape.remove()
		
