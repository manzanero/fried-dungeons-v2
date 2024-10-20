class_name Element
extends CharacterBody3D


signal property_changed(property_name: StringName, old_value: Variant, new_value: Variant)


var map: Map
var level: Level


@export var snapping := Game.PIXEL_SNAPPING_QUARTER 
@export var is_ceiling_element: bool
@export var init_properties := []


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
var is_selected: bool : set = _set_selected
var is_preview: bool : set = _set_preview
var is_rotated: bool : set = _set_rotated

var target_position: Vector3
var is_moving_to_target: bool
var position_2d: Vector2 :
	get: return Utils.v3_to_v2(position)
var rotation_y: float :
	get: return rotation.y

var properties_values: Dictionary :
	get:
		var property_values := {}
		for property_name in properties:
			property_values[property_name] = properties[property_name].value
		return property_values

@onready var elements: Node3D = $Elements


func init(_level: Level, _id: String, _position_2d: Vector2, _properties := {}, _rotation_y := 0.0):
	id = _id
	level = _level
	map = level.map
	position = Vector3(_position_2d.x, 0, _position_2d.y)
	rotation.y = _rotation_y
	level.elements_parent.add_child(self)
	_init_property_list(_properties)
	property_changed.connect(_on_property_changed)
	return self


func _init_property_list(_properties):
	for property_array in init_properties:
		var property_name: String = property_array[1]
		var value = _properties.get(property_name, property_array[3])
		init_property(property_array[0], property_name, property_array[2], value)
		change_property(property_name, value)
	
	
func _on_property_changed(property_name: String, _old_value: Variant, new_value: Variant) -> void:
	change_property(property_name, new_value)


## override in subclass
func change_property(_property_name: String, _new_value: Variant) -> void:
	pass


func init_property(container: String, property_name: StringName, property_hint: StringName, default_value: Variant = null) -> void:
	properties[property_name] = Property.new(container, property_hint, default_value)


func set_property_value(property_name: StringName, new_value: Variant) -> void:
	if new_value is Property:
		if not properties.has(property_name):
			init_property(properties.container, property_name, properties.hint, new_value.value)
			return

		new_value = new_value.value

	var old_value = properties.get(property_name).value if properties.has(property_name) else null
	if old_value == new_value:
		return

	properties[property_name].value = new_value
	property_changed.emit(property_name, old_value, new_value)
	
	if property_name == "label":
		Game.ui.tab_elements.changed_element(self)


func get_property(property_name: StringName, default: Variant = null) -> Property:
	return properties.get(property_name, default)
		
		
func update_properties():
	for property_name in properties:
		property_changed.emit(property_name, null, properties[property_name].value)
		
		
## override
func _set_dragged(value: bool) -> void:
	is_dragged = value


## override
func _set_rotated(value: bool) -> void:
	is_rotated = value


## override
func _set_preview(value: bool) -> void:
	is_preview = value


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


func get_target_hovered() -> Vector3:
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
		_dragged_process()
	
	if is_moving_to_target:
		var vector_to_target := target_position - position
		if not vector_to_target.is_zero_approx():
			var distance_to_target := vector_to_target.length()
			var direction_to_target := vector_to_target.normalized()
			const input_velocity: float = 1000
			var velocity_to_target := clampf(delta * distance_to_target * input_velocity, 0, 10)
			velocity = direction_to_target * velocity_to_target
			if velocity and move_and_slide():
				target_position = position
		else:
			is_moving_to_target = false
			
			
func _preview_process() -> void:
	if Game.ui.is_mouse_over_scene_tab:
		var target_hovered := get_target_hovered()
		if is_rotated:
			look_target(target_hovered)
		else:
			position = target_hovered
	else:
		position = Game.ui.selected_map.camera.focus_hint_3d.global_position
		
			
func _dragged_process() -> void:
	is_rotated = Input.is_action_pressed("rotate")
	
	var target_hovered := get_target_hovered()
	if multiplayer.is_server() and Input.is_key_pressed(KEY_CTRL):
		if is_rotated:
			look_target(target_hovered)
		else:
			position = target_hovered
			
		Game.server.rpcs.set_element_position.rpc(map.slug, level.index, id, position, rotation_y)
	
	if is_rotated:
		look_target(target_hovered)
	else:
		target_position = target_hovered
		is_moving_to_target = true
		
	Game.server.rpcs.set_element_target.rpc(map.slug, level.index, id, target_position, rotation_y)


## override
func remove():
	queue_free()
	level.elements.erase(id)
	
	Game.ui.tab_elements.remove_element(self)
	Game.ui.tab_properties.reset()
	

class Property:
	var hint: StringName
	var value: Variant
	var container: String
	
	func _init(_container: String, _hint: StringName, _value: Variant):
		hint = _hint
		value = _value
		container = _container

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
