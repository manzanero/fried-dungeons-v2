class_name LevelElementInstancingState
extends LevelBaseState


enum {
	OMNILIGHT, ENTITY_3D, ENTITY_BILLBOARD, PROP_3D, PROP_DECAL
}


var mode: int
var material_index_selected: int :
	get: return Game.ui.tab_builder.material_index_selected


var preview_label: String
var preview_blueprint: CampaignBlueprint
var detached_blueprint: bool
var preview_rotation: float
var preview_flipped: bool
var preview_properties := {}


func _enter_state(previous_state: String) -> void:
	super(previous_state)
	Game.ui.build_border.visible = true
	selector.grid.visible = true
	selector.column.visible = false
	selector.position_2d = Game.NULL_POSITION_2D
	preview_label = ""
	preview_blueprint = null
	preview_properties = {}
	preview_rotation = 0.0
	preview_flipped = false
	level.preview_element = null
	for element: Element in level.elements_selected.values():
		element.is_selected = false

func _exit_state(next_state: String) -> void:
	super(next_state)
	Game.ui.build_border.visible = false
	if is_instance_valid(level.preview_element):
		level.preview_element.remove()
	#if is_instance_valid(level.preview_element):
		#level.preview_element.call_deferred("remove")
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
			preview_properties = preview_blueprint.properties.duplicate()
		if not preview_label:
			preview_label = "New Entity"
		preview_properties["label"] = _valid_element_label(preview_label)
		entity = map.instancer.create_entity(level, Utils.random_string(8, true), 
				selector.position_2d, preview_properties, preview_rotation, preview_flipped, true)
		if not detached_blueprint:
			entity.set_property_value("blueprint", preview_blueprint)
		entity.is_selected = true
		entity.edit_properties()
		entity.cached_light = level.get_element_light(selector.position_2d)
		entity.update_light()
		entity.selector_disabled = true
		level.preview_element = entity
		
	entity.is_rotated = Input.is_action_pressed("rotate")
		
	if Input.is_action_just_released("middle_click") and not level.mouse_move:
		var hit_info := Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, Game.selector_ray)
		if hit_info:
			var collider = hit_info.collider
			while not collider is Element:
				collider = collider.get_parent()
			var hovered_entity := collider as Entity
			if hovered_entity:
				entity.set_property_values(hovered_entity.get_property_values())
				preview_label = hovered_entity.label
				entity.set_property_value("label", _valid_element_label(hovered_entity.label))
				entity.update()
				entity.selector_disabled = true
				Game.ui.tab_properties.refresh()
	
	if Input.is_action_just_released("left_click") and Game.ui.scene_tab_has_focus:
		var id = Utils.random_string(8, true)
		map.instancer.create_entity(level, id, 
				entity.position_2d, entity.properties_values, entity.rotation_y)
	
		Game.server.rpcs.create_entity.rpc(map.slug, level.index, id, 
				entity.position_2d, entity.get_raw_property_values(), entity.rotation_y)
				
		entity.set_property_value("label", _valid_element_label(preview_label))
	

func process_instance_light():
	var light := level.preview_element as Light if is_instance_valid(level.preview_element) else null
	if not light:
		if preview_blueprint:
			preview_properties = preview_blueprint.properties.duplicate()
		if not preview_label:
			preview_label = "New Light"
		preview_properties["label"] = _valid_element_label(preview_label)
		light = map.instancer.create_light(level, Utils.random_string(8, true), 
				selector.position_2d, preview_properties, preview_rotation, preview_flipped, true)
		if not detached_blueprint:
			light.set_property_value("blueprint", preview_blueprint)
		light.is_selected = true
		light.edit_properties()
		light.cached_light = level.get_element_light(selector.position_2d)
		light.update_light()
		light.selector_disabled = true
		level.preview_element = light
		
	if Input.is_action_just_released("middle_click") and not level.mouse_move:
		var hit_info := Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, Game.selector_ray)
		if hit_info:
			var hovered_light := hit_info.collider.get_parent() as Light
			if hovered_light:
				light.properties = hovered_light.properties.duplicate()
				preview_label = _valid_element_label(hovered_light.label)
				light.set_property_value("label", _valid_element_label(hovered_light.label))
				light.update()
				light.selector_disabled = true
				Game.ui.tab_properties.refresh()
	
	if Input.is_action_just_released("left_click") and Game.ui.scene_tab_has_focus:
		var id = Utils.random_string(8, true)
		map.instancer.create_light(level, id, 
				light.position_2d, light.properties_values, light.rotation_y)
		
		Game.server.rpcs.create_light.rpc(map.slug, level.index, id, 
				light.position_2d, light.properties_values, light.rotation_y)
				
		light.set_property_value("label", _valid_element_label(preview_label))
		light.set_property_value("label", _valid_element_label(preview_label))


func process_instance_prop():
	var prop := level.preview_element as Prop if is_instance_valid(level.preview_element) else null
	if not prop:
		if preview_blueprint:
			preview_properties = preview_blueprint.properties.duplicate()
		if not preview_label:
			preview_label = "New Prop"
		preview_properties["label"] = _valid_element_label(preview_label)
		prop = map.instancer.create_prop(level, Utils.random_string(8, true), 
				selector.position_2d, preview_properties, preview_rotation, preview_flipped, true)
		if not detached_blueprint:
			prop.set_property_value("blueprint", preview_blueprint)
		prop.is_selected = true
		prop.edit_properties()
		prop.cached_light = level.get_element_light(selector.position_2d)
		prop.update_light()
		prop.selector_disabled = true
		level.preview_element = prop
		
	if Input.is_action_just_released("middle_click") and not level.mouse_move:
		var hit_info := Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, Game.selector_ray)
		if hit_info:
			var collider = hit_info.collider
			while not collider is Element:
				collider = collider.get_parent()
			var hovered_prop := collider as Prop
			if hovered_prop:
				prop.properties = hovered_prop.properties.duplicate()
				preview_label = _valid_element_label(hovered_prop.label)
				prop.set_property_value("label", _valid_element_label(hovered_prop.label))
				prop.update()
				prop.selector_disabled = true
				Game.ui.tab_properties.refresh()
		
	prop.is_rotated = Input.is_action_pressed("rotate")
	
	if Input.is_action_just_released("left_click") and Game.ui.scene_tab_has_focus:
		var id = Utils.random_string(8, true)
		var new_prop := map.instancer.create_prop(level, id, 
				prop.position_2d, prop.properties_values, prop.rotation_y)
				
		new_prop.cached_light = level.get_element_light(selector.position_2d)
		new_prop.update_light()
	
		Game.server.rpcs.create_prop.rpc(map.slug, level.index, id,
				prop.position_2d, prop.properties_values, prop.rotation_y)
	
		prop.set_property_value("label", _valid_element_label(preview_label))


func _valid_element_label(label: String) -> String:
	if not _element_label_exist(label):
		return label
	
	var regex = RegEx.new()
	regex.compile(r"^(.*?)(?:\s+(\d+))?$")
	var matches := regex.search(label)
	var base_name := label.strip_edges()
	var siblins := 1
	if matches:
		base_name = matches.get_string(1).strip_edges()
		if matches.get_string(2):
			siblins = int(matches.get_string(2))
		
	siblins += 1
	var candidate = "%s %d" % [base_name, siblins]
	while _element_label_exist(candidate):
		siblins += 1
		candidate = "%s %d" % [base_name, siblins]
	return candidate

func _element_label_exist(label: String) -> bool:
	for element: Element in level.elements.values():
		if element.label == label:
			return true
	return false
	
