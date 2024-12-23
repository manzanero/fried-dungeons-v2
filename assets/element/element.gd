class_name Element
extends CharacterBody3D


signal property_changed(property_name: StringName, old_value: Variant, new_value: Variant)


var map: Map
var level: Level


@export var snapping := Game.PIXEL_SNAPPING_QUARTER 
@export var is_ceiling_element: bool
@export var init_properties := {}


var properties := {}
var id: String :
	set(value): 
		id = value
		name = id

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
	get: return rotation.y
var flipped := false : set = _set_flipped

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
	return self


func _init_property_list(_properties):
	for property_name in init_properties:
		var property_data: Dictionary = init_properties[property_name]
		var value = _properties.get(property_name, property_data.default)
		
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


func set_property_value(property_name: String, new_value: Variant) -> void:
	if new_value is Property:
		if not properties.has(property_name):
			init_property(properties.container, property_name, 
					new_value.hint, new_value.params, new_value.value)
			return

		new_value = new_value.value

	var old_value = properties.get(property_name).value if properties.has(property_name) else null
	if old_value == new_value:
		return

	properties[property_name].value = new_value
	property_changed.emit(property_name, old_value, new_value)
	
	if property_name == "label":
		Game.ui.tab_elements.changed_element(self)


func get_property(property_name: String, default: Variant = null) -> Property:
	return properties.get(property_name, default)
		
		
func update_properties():
	for property_name in properties:
		property_changed.emit(property_name, null, properties[property_name].value)
		
		
## override
func _set_dragged(value: bool) -> void:
	is_dragged = value
	
	if not value:
		if Game.server.is_peer_connected:  # may disconnect while dragging
			Game.server.rpcs.set_element_position.rpc(map.slug, level.index, id, global_position, rotation_y)


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


## override
func _set_selected(value: bool) -> void:
	is_selected = value
	if value:
		if is_instance_valid(level.element_selected):
			level.element_selected.is_selected = false
			
		level.element_selected = self
		Game.ui.tab_properties.element_selected = self
		
	elif Game.ui.tab_properties.element_selected == self:
		Game.ui.tab_properties.element_selected = null
		
		is_dragged = false


func _get_target_hovered() -> Vector3:
	if is_rotated: 
		return Utils.v2_to_v3(level.exact_position_hovered)
		
	var drag_position := level.ceilling_hovered if is_ceiling_element else level.position_hovered
	drag_position -= level.drag_offset
	if not Input.is_key_pressed(KEY_ALT): 
		drag_position = drag_position.snapped(snapping)
		
	return Utils.v2_to_v3(drag_position)


func look_target(target_hovered: Vector3):
	if target_hovered.distance_to(position) < 0.125:
		return
		
	look_at(target_hovered, Vector3.UP, true)
	rotation.y = snapped(rotation.y, 0.001 if Input.is_key_pressed(KEY_ALT) else PI / 8)


func _physics_process(delta: float) -> void:
	if is_preview:
		_preview_process()
		return
	
	if is_dragged:
		set_multiplayer_authority(Game.server.presence.id)
		_flip_process()
		_dragged_process()
	
	if is_moving_to_target:
		var vector_to_target := target_position - global_position
		if vector_to_target.length() > 0.001:
			var distance_to_target := vector_to_target.length()
			var direction_to_target := vector_to_target.normalized()
			const input_velocity: float = 1000
			var velocity_to_target := clampf(delta * distance_to_target * input_velocity, 0, 10)
			velocity = direction_to_target * velocity_to_target
			if velocity and move_and_slide():
				if is_multiplayer_authority():
					var ticks_msec := Time.get_ticks_msec()
					if next_update_ticks_msec < ticks_msec:
						next_update_ticks_msec = ticks_msec + 100
						Game.server.rpcs.set_element_target.rpc(map.slug, level.index, id, target_position, rotation)
						
					target_position = global_position
		else:
			is_moving_to_target = false
			if is_multiplayer_authority():
				Game.server.rpcs.set_element_position.rpc(map.slug, level.index, id, global_position, rotation_y)
			
			
func _preview_process() -> void:
	if not Game.ui.is_mouse_over_scene_tab:
		global_position = Game.ui.selected_map.camera.focus_hint_3d.global_position
		return
		
	var target_hovered := _get_target_hovered()
	if is_rotated:
		look_target(target_hovered)
	else:
		global_position = target_hovered
		target_position = target_hovered


func _flip_process() -> void:
	if Input.is_action_just_pressed("flip"):
		flipped = not flipped
		Game.server.rpcs.set_element_position.rpc(map.slug, level.index, id, global_position, rotation_y, flipped)


func _dragged_process() -> void:
	is_rotated = Input.is_action_pressed("rotate")
	
	var target_hovered := _get_target_hovered()
	var ticks_msec := Time.get_ticks_msec()
	
	# forced change
	if multiplayer.is_server() and Input.is_key_pressed(KEY_CTRL):
		if is_rotated:
			look_target(target_hovered)
		else:
			global_position = target_hovered

		if next_update_ticks_msec < ticks_msec:
			next_update_ticks_msec = ticks_msec + 100
			Game.server.rpcs.set_element_position.rpc(map.slug, level.index, id, global_position, rotation_y)
			
		return
	
	# target change
	if is_rotated:
		look_target(target_hovered)
	else:
		var vector_to_target := target_hovered - global_position
		if vector_to_target.length() < 0.001:
			return
			
		target_position = target_hovered
		is_moving_to_target = true
	
	if next_update_ticks_msec < ticks_msec:
		next_update_ticks_msec = ticks_msec + 100
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
		match hint:
			Hints.COLOR:
				value = Utils.html_color_to_color(_value)
			_:
				value = _value
				
	func get_raw():
		match hint:
			Hints.COLOR:
				return Utils.color_to_html_color(value)
			_:
				return value

	class Hints:
		const BOOL = "bool_hint"
		const COLOR = "color_hint"
		const FLOAT = "float_hint"
		const INTEGER = "integer_hint"
		const STRING = "string_hint"
		const TEXT_AREA = "text_area_hint"
		const VECTOR_2 = "vector_2_hint"
		const TEXTURE = "texture_hint"
		const CHOICE = "choice_hint"
