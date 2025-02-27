class_name LevelElementInstancingState
extends LevelBaseState


enum {
	OMNILIGHT, ENTITY_3D, ENTITY_BILLBOARD, PROP_3D, PROP_DECAL
}


var mode: int
var material_index_selected: int :
	get: return Game.ui.tab_builder.material_index_selected


var preview_blueprint: CampaignBlueprint
var detached_blueprint: bool
var preview_rotation: float
var preview_properties := {}
#var instance_once := false


func _enter_state(previous_state: String) -> void:
	super(previous_state)
	Game.ui.build_border.visible = true
	selector.grid.visible = true
	selector.column.visible = false
	selector.position_2d = Game.NULL_POSITION_2D
	preview_blueprint = null
	
	preview_properties = {}
	preview_rotation = 0.0
	level.preview_element = null
	#instance_once = false


func _exit_state(next_state: String) -> void:
	super(next_state)
	Game.ui.build_border.visible = false
	if is_instance_valid(level.preview_element):
		level.preview_element.call_deferred("remove")
	level.preview_element = null


func _process_state(_delta: float) -> String:
	var next_state := super(_delta)
	if next_state != Level.State.KEEP:
		return next_state
	
	match mode:
		OMNILIGHT:
			process_instance_light()
		ENTITY_3D:
			process_instance_entity()
		PROP_3D:
			process_instance_prop()
			
	return Level.State.KEEP


func _physics_process_state(_delta: float) -> String:
	match mode:
		OMNILIGHT:
			process_ceilling_hitted()
		ENTITY_3D:
			process_ground_hitted()
			process_change_grid()
		PROP_3D:
			process_ground_hitted()
			process_change_grid()
			
	return Level.State.KEEP


func process_instance_entity():
	var entity := level.preview_element as Entity if is_instance_valid(level.preview_element) else null
	if not entity:
		if preview_blueprint:
			preview_properties = preview_blueprint.properties
		entity = map.instancer.create_entity(level, Utils.random_string(8, true), 
				selector.position_2d, preview_properties, preview_rotation)
		if not detached_blueprint:
			entity.set_property_value("blueprint", preview_blueprint)
		entity.is_preview = true
		entity.selector_disabled = true
		level.select(entity)
		level.preview_element = entity
		
	entity.is_rotated = Input.is_action_pressed("rotate")
		
	if Input.is_action_just_pressed("key_c"):
		var hit_info := Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, Game.selector_ray)
		if hit_info:
			var collider = hit_info.collider
			while not collider is Element:
				collider = collider.get_parent()
			var hovered_entity := collider as Entity
			if hovered_entity:
				entity.properties = hovered_entity.properties
				Game.ui.tab_properties.element_selected = entity
	
	if Input.is_action_just_released("left_click") and Game.ui.scene_tab_has_focus:
		var id = Utils.random_string(8, true)
		map.instancer.create_entity(level, id, 
				entity.position_2d, entity.properties_values, entity.rotation_y)
	
		Game.server.rpcs.create_entity.rpc(map.slug, level.index, id, 
				entity.position_2d, entity.get_raw_property_values(), entity.rotation_y)
	

func process_instance_light():
	var light := level.preview_element as Light if is_instance_valid(level.preview_element) else null
	if not light:
		if preview_blueprint:
			preview_properties = preview_blueprint.properties
		light = map.instancer.create_light(level, Utils.random_string(8, true), 
				selector.position_2d, preview_properties)
		if not detached_blueprint:
			light.set_property_value("blueprint", preview_blueprint)
		light.is_preview = true
		light.selector_disabled = true
		level.select(light)
		level.preview_element = light
		
	if Input.is_action_just_pressed("key_c"):
		var hit_info := Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, Game.selector_ray)
		if hit_info:
			var hovered_light := hit_info.collider.get_parent() as Light
			if hovered_light:
				light.properties = hovered_light.properties
				Game.ui.tab_properties.element_selected = light
	
	if Input.is_action_just_released("left_click") and Game.ui.scene_tab_has_focus:
		var id = Utils.random_string(8, true)
		map.instancer.create_light(level, id, 
				light.position_2d, light.properties_values, light.rotation_y)
		
		Game.server.rpcs.create_light.rpc(map.slug, level.index, id, 
				light.position_2d, light.properties_values, light.rotation_y)


func process_instance_prop():
	var prop := level.preview_element as Prop if is_instance_valid(level.preview_element) else null
	if not prop:
		if preview_blueprint:
			preview_properties = preview_blueprint.properties
		prop = map.instancer.create_prop(level, Utils.random_string(8, true), 
				selector.position_2d, preview_properties, preview_rotation)
		if not detached_blueprint:
			prop.set_property_value("blueprint", preview_blueprint)
		prop.is_preview = true
		prop.selector_disabled = true
		level.select(prop)
		level.preview_element = prop
		
	if Input.is_action_just_pressed("key_c"):
		var hit_info := Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, Game.selector_ray)
		if hit_info:
			var collider = hit_info.collider
			while not collider is Element:
				collider = collider.get_parent()
			var hovered_prop := collider as Prop
			if hovered_prop:
				prop.properties = hovered_prop.properties
				Game.ui.tab_properties.element_selected = prop
		
	prop.is_rotated = Input.is_action_pressed("rotate")
	
	if Input.is_action_just_released("left_click") and Game.ui.scene_tab_has_focus:
		var id = Utils.random_string(8, true)
		map.instancer.create_prop(level, id, 
				prop.position_2d, prop.properties_values, prop.rotation_y)
	
		Game.server.rpcs.create_prop.rpc(map.slug, level.index, id,
				prop.position_2d, prop.properties_values, prop.rotation_y)
