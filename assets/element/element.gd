class_name Element
extends CharacterBody3D


signal moved
signal property_changed(property_name: StringName, old_value: Variant, new_value: Variant)


var map: Map
var level: Level


var snapping := Game.SNAPPING_QUARTER 
var is_ceiling_element: bool
var blueprint: CampaignBlueprint

var init_properties := {}
var properties := {} :
	set(value):
		properties = value
		update_properties()
var id: String :
	set(value):
		id = value
		name = id

var type := "element"
var label := "Unknown"
var color := Color.BLUE
var description := ""
var icon: Texture2D = null


var is_dragged: bool : set = _set_dragged
var is_selectable: bool : set = _set_selectable
var is_selected: bool : set = _set_selected
var is_preview: bool : set = _set_preview
var is_rotated: bool : set = _set_rotated

var next_update_ticks_msec := Time.get_ticks_msec()
var target_position: Vector3
var is_moving_to_target: bool
var position_2d: Vector2 :
	get: return Utils.v3_to_v2(global_position)
var rotation_y: float :
	get: return snappedf(rotation.y, 0.001)
var flipped := false : set = _set_flipped
var element_velocity := 5.0

var properties_values: Dictionary :
	get:
		var property_values := {}
		for property_name in properties:
			property_values[property_name] = properties[property_name].value
		return property_values

var parent: Element : set = _set_parent

@onready var elements_parent: Node3D = $Elements


func init(_level: Level, _id: String, _position_2d: Vector2, _properties := {}, 
		_rotation_y := 0.0, _flipped := false):
	id = _id
	level = _level
	map = level.map
	level.elements_parent.add_child(self)
	global_position = Vector3(_position_2d.x, 0, _position_2d.y)
	rotation.y = _rotation_y
	flipped = _flipped
	is_selectable = Game.campaign.is_master
	_init_property_list(_properties)
	property_changed.connect(_on_property_changed)
	update()
	return self

# override 
func update():
	pass


func _init_property_list(_properties_data):
	for property_name in init_properties:
		var property_data: Dictionary = init_properties[property_name]
		var value = _properties_data.get(property_name, property_data.default)
		
		init_property(property_data.container, property_name, property_data.hint, property_data.params, value)
		change_property(property_name, value)
	
	
func _on_property_changed(property_name: String, _old_value: Variant, new_value: Variant) -> void:
	change_property(property_name, new_value)


## override in subclass
func change_property(_property_name: String, _new_value: Variant) -> void:
	pass


func init_property(container: String, property_name: String, 
		hint: String, params: Dictionary, default: Variant) -> void:
	properties[property_name] = Property.new(container, hint, params, default)


func get_property(property_name: String, default: Variant = null) -> Property:
	return properties.get(property_name, default)


func set_property_value(property_name: String, new_value: Variant) -> Property:
	var property := get_property(property_name)
	var old_value: Variant = property.value
	if old_value == new_value:
		return

	property.value = new_value
	property_changed.emit(property_name, old_value, new_value)
	
	if property_name == "label":
		Game.ui.tab_elements.changed_element(self)
		
	return property


func set_raw_property_value(property_name: String, new_value: Variant) -> Property:
	var property := get_property(property_name)
	var old_value: Variant = property.value
	var parsed_new_value: Variant = property.set_raw(new_value)
	if old_value == parsed_new_value:
		return

	property.value = parsed_new_value
	property_changed.emit(property_name, old_value, parsed_new_value)
	return property


func set_property_values(property_values: Dictionary) -> Dictionary:
	for property_name in property_values:
		set_property_value(property_name, property_values[property_name])
	return properties


func get_raw_property_values() -> Dictionary:
	var raw_properties := {}
	for property_name in properties:
		raw_properties[property_name] = properties[property_name].get_raw()
	return raw_properties


func set_raw_property_values(raw_property_values: Dictionary) -> Dictionary:
	for property_name in raw_property_values:
		set_raw_property_value(property_name, raw_property_values[property_name])
	return properties
		
		
func update_properties():
	for property_name in properties:
		property_changed.emit(property_name, null, properties[property_name].value)
		
		
## override
func _set_dragged(value: bool) -> void:
	if is_dragged and not value:
		target_position = position.snappedf(Game.U)
		if Game.server.is_peer_connected:  # may disconnect while dragging
			Game.server.rpcs.set_element_position.rpc(map.slug, level.index, id, global_position, rotation_y)
	is_dragged = value


## override
func _set_rotated(value: bool) -> void:
	is_rotated = value


## override
func _set_flipped(value: bool) -> void:
	flipped = value


## override
func _set_preview(value: bool) -> void:
	is_preview = value


## override
func _set_selectable(value: bool) -> void:
	is_selectable = value
	
	if not is_selectable and is_selected:
		if not Game.player_is_master:  # keep selected if master, to continue editing
			is_selected = false


## override
func _set_selected(value: bool) -> void:
	var current_element_selected := level.element_selected
	if is_instance_valid(current_element_selected) and current_element_selected != self:
		level.element_selected = null
		current_element_selected.is_selected = false

	is_selected = value
	
	if value:
		level.element_selected = self
		Game.ui.tab_properties.element_selected = self
		
	else:
		is_dragged = false
		
		if Game.ui.tab_properties.element_selected == self:
			Game.ui.tab_properties.element_selected = null


func _get_target_hovered() -> Vector3:
	if is_rotated: 
		return Utils.v2_to_v3(level.exact_position_hovered)
		
	var drag_position := level.exact_ceilling_hovered if is_ceiling_element else level.exact_position_hovered
	drag_position -= level.drag_offset
	if Input.is_key_pressed(KEY_ALT): 
		drag_position = drag_position.snappedf(Game.U)
	else:
		drag_position = drag_position.snappedf(snapping)
		
	return Utils.v2_to_v3(drag_position)


func look_target(delta: float, target_hovered: Vector3):
	if target_hovered.distance_to(position) < 0.125:
		return
	
	var direction := -position.direction_to(target_hovered)
	var snapped_direction = direction
	if not Input.is_key_pressed(KEY_ALT):
		snapped_direction = snap_direction_to_angle(direction, PI / 4)
	
	var current_quat := Quaternion(global_transform.basis)
	var target_quat := Quaternion(Basis.looking_at(snapped_direction, Vector3.UP))
	
	if basis.z.angle_to(-snapped_direction) < PI / 32:
		current_quat = target_quat
		
	var new_quat := target_quat
	if not Input.is_key_pressed(KEY_CTRL):
		new_quat = current_quat.slerp(target_quat, 16 * delta)
		
	global_transform.basis = Basis(new_quat)
	
	
func snap_direction_to_angle(direction: Vector3, step: float) -> Vector3:
	var angle = atan2(direction.x, direction.z)  # Get current yaw angle
	var snapped_angle = snapped(angle, step)  # Snap to nearest step
	return Vector3(sin(snapped_angle), 0, cos(snapped_angle))  # Convert back to a direction



func _physics_process(delta: float) -> void:
	if is_preview:
		_preview_process(delta)
		return
	
	if is_dragged and (Game.campaign.is_master or not Game.flow.is_paused):
		#set_multiplayer_authority(multiplayer.get_unique_id())  # TODO
		_flip_process()
		_dragged_process(delta)
	
	if is_moving_to_target:
		moved.emit()
		var vector_to_target := target_position - global_position
		if vector_to_target.length() > 0.001:
			var distance_to_target := vector_to_target.length()
			var direction_to_target := vector_to_target.normalized()
			const input_velocity: float = 1000
			var velocity_to_target := clampf(delta * distance_to_target * input_velocity, 0, element_velocity)
			velocity = direction_to_target * velocity_to_target
			if move_and_slide() and velocity.length() < 0.001:
				if next_update_ticks_msec < Game.ticks_msec:
					next_update_ticks_msec = Game.ticks_msec + 100
					Game.server.rpcs.set_element_target.rpc(map.slug, level.index, id, target_position, rotation)

				is_moving_to_target = false
				target_position = global_position
					
			#if move_and_slide():
				#if is_multiplayer_authority():
					#var ticks_msec := Time.get_ticks_msec()
					#if next_update_ticks_msec < ticks_msec:
						#next_update_ticks_msec = ticks_msec + 100
						#Game.server.rpcs.set_element_target.rpc(map.slug, level.index, id, target_position, rotation)
			#
					#if velocity < 0.001 * Vector3.ONE:
						#is_moving_to_target = false
						#target_position = global_position
		else:
			is_moving_to_target = false
			target_position = global_position
			#if is_multiplayer_authority():
				#Game.server.rpcs.set_element_position.rpc(map.slug, level.index, id, global_position, rotation_y)
			
			
func _preview_process(delta: float) -> void:
	moved.emit()
	if not Game.ui.is_mouse_over_scene_tab:
		global_position = Game.ui.selected_map.camera.focus_hint_3d.global_position
		return
		
	if Input.is_action_just_pressed("flip"):
		flipped = not flipped
		Game.server.rpcs.set_element_position.rpc(map.slug, level.index, id, global_position, rotation_y, flipped)
		
	var target_hovered := _get_target_hovered()
	if is_rotated:
		look_target(delta, target_hovered)
	else:
		global_position = target_hovered
		target_position = target_hovered


func _flip_process() -> void:
	if Input.is_action_just_pressed("flip"):
	#if Input.is_action_just_pressed("middle_click"):
		flipped = not flipped
		Game.server.rpcs.set_element_position.rpc(map.slug, level.index, id, global_position, rotation_y, flipped)


func _dragged_process(delta: float) -> void:
	moved.emit()
	is_rotated = Input.is_action_pressed("rotate")
	#is_rotated = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	
	#if not level.mouse_move:
		#return
	#level.mouse_move = false
	
	var target_hovered := _get_target_hovered()
	
	# forced change
	if multiplayer.is_server() and Input.is_key_pressed(KEY_CTRL):
		if is_rotated:
			look_target(delta, target_hovered)
		else:
			global_position = target_hovered

		if next_update_ticks_msec < Game.ticks_msec:
			next_update_ticks_msec = Game.ticks_msec + 100
			Game.server.rpcs.set_element_position.rpc(map.slug, level.index, id, global_position, rotation_y)
			
		return
	
	# target change
	if is_rotated:
		look_target(delta, target_hovered)
	else:
		var vector_to_target := target_hovered - global_position
		if vector_to_target.length() < 0.001:
			return
			
		target_position = target_hovered
		is_moving_to_target = true
	
	if next_update_ticks_msec < Game.ticks_msec:
		next_update_ticks_msec = Game.ticks_msec + 100
		Game.server.rpcs.set_element_target.rpc(map.slug, level.index, id, target_position, rotation)
		

func _set_parent(value: Element):
	reparent(value.elements_parent if value else level.elements_parent, true)


## override
func remove():
	for element: Element in elements_parent.get_children():
		element.remove()
		
	Game.ui.tab_elements.remove_element(self)
	Game.ui.tab_properties.reset()
	
	level.elements.erase(id)
	
	queue_free()
	
	
func _set_blueprint(_blueprint: CampaignBlueprint) -> void:
	if blueprint:
		blueprint.blueprint_changed.disconnect(_on_blueprint_changed)
		blueprint.blueprint_removed.disconnect(_on_blueprint_removed)
	blueprint = _blueprint
	if blueprint:
		blueprint.blueprint_changed.connect(_on_blueprint_changed)
		blueprint.blueprint_removed.connect(_on_blueprint_removed)


func _on_blueprint_changed() -> void:
	set_property_values(blueprint.properties)
	
	Debug.print_info_message("Element %s changed Blueprint: " + blueprint.path)
	
	Game.server.rpcs.change_element_properties.rpc(map.slug, level.index, id, get_raw_property_values())


func _on_blueprint_removed() -> void:
	set_property_value("blueprint", null)
	if is_selected:
		Game.ui.tab_properties.refresh()
	Debug.print_info_message("Element %s removed Blueprint")


class Property:
	var container: String
	var hint: StringName
	var params: Dictionary
	var value: Variant
	
	func _init(_container: String, _hint: String, _params: Dictionary, _value: Variant):
		container = _container
		hint = _hint
		params = _params
		value = _value
	
	func set_raw(_value):
		value = Element.set_raw_property(hint, _value)
		return value
	
	func get_raw():
		return Element.get_raw_property(hint, value)


static func set_raw_property(hint: StringName, value: Variant) -> Variant:
	match hint:
		Hint.COLOR:
			return Utils.html_color_to_color(value)
		Hint.BLUEPRINT:
			return Game.blueprints.get(value) if value else null
	return value

static func get_raw_property(hint: StringName, value: Variant) -> Variant:
	match hint:
		Hint.COLOR:
			return Utils.color_to_html_color(value)
		Hint.BLUEPRINT:
			return value.id if value else ""
	return value


class Hint:
	const BOOL = "bool_hint"
	const COLOR = "color_hint"
	const FLOAT = "float_hint"
	const INTEGER = "integer_hint"
	const STRING = "string_hint"
	const TEXT_AREA = "text_area_hint"
	const VECTOR_2 = "vector_2_hint"
	const TEXTURE = "texture_hint"
	const CHOICE = "choice_hint"
	const BLUEPRINT = "blueprint_hint"
