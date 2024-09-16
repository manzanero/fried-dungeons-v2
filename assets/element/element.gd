class_name Element
extends CharacterBody3D


signal property_changed(property_name: StringName, old_value: Variant, new_value: Variant)


var map: Map
var level: Level


@export var properties := {}


var id: String :
	set(value): 
		id = value
		name = id

var label := "Unknown"
var color := Color.BLUE
var icon: Texture2D = null


var is_dragged := false
var is_selected: bool : set = _set_selected
var is_preview: bool : set = _set_preview
var target_position: Vector3
var is_moving_to_target: bool


var properties_values: Dictionary :
	get:
		var property_values := {}
		for property_name in properties:
			property_values[property_name] = properties[property_name].value
		return property_values

@onready var elements: Node3D = $Elements


func init(_level: Level, _id: String, _position_2d: Vector2, _properties := {}):
	id = _id
	level = _level
	map = level.map
	position = Vector3(_position_2d.x, 0, _position_2d.y)
	level.elements_parent.add_child(self)
	_init_property_list(_properties)
	property_changed.connect(_on_property_changed)
	return self


## override in subclass
func _init_property_list(_properties):
	pass


## override in subclass
func _on_property_changed(_property_name: String, _old_value: Variant, _new_value: Variant) -> void:
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


func get_property(property_name: StringName, default: Variant = null) -> Property:
	return properties.get(property_name, default)
		
		
func update_properties():
	for property_name in properties:
		property_changed.emit(property_name, null, properties[property_name].value)


func get_target_hovered():
	if Input.is_key_pressed(KEY_ALT):
		return Utils.v2_to_v3(level.position_hovered)
	else:
		return Utils.v2_to_v3(level.position_hovered.snapped(Game.PIXEL_SNAPPING_QUARTER))


func _set_preview(value: bool) -> void:
	is_preview = value
	if not value:
		Game.server.rpcs.set_element_position.rpc(map.slug, level.index, id, position)


## override
func _set_selected(_value: bool) -> void:
	pass
		

func _physics_process(delta: float) -> void:
	if is_preview:
		position = get_target_hovered()
		return
		
	if is_dragged:
		if multiplayer.is_server() and Input.is_key_pressed(KEY_CTRL):
			position = get_target_hovered()
			Game.server.rpcs.set_element_position.rpc(map.slug, level.index, id, position)
		
		target_position = get_target_hovered()
		is_moving_to_target = true
		Game.server.rpcs.set_element_target.rpc(map.slug, level.index, id, target_position)
	
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


func remove():
	queue_free()
	level.elements.erase(id)
	

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
		const BOOL = &"bool_hint"
		const COLOR = &"color_hint"
		const FLOAT = &"float_hint"
		const INTEGER = &"integer_hint"
		const STRING = &"string_hint"
		const TEXT_AREA = &"text_area_hint"
