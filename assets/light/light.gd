class_name Light
extends Element


var level : Level

var id : String : 
	set(value):
		name = value
	get:
		return str(name)


@export var range_radius := 5.0 :
	set(value):
		range_radius = value
		if omni_light_3d:
			omni_light_3d.omni_range = value

@export var active := true :
	set(value):
		active = value
		omni_light_3d.visible = value
		
		if active:
			level.active_lights.append(self)
			inner_material.albedo_color = Color(0.75, 0.75, 0.75, 0.5)
			
			# Only a certain number of lights can be active at a time
			if level.active_lights.size() > Game.MAX_LIGHTS:
				Debug.print_message(Debug.ERROR, "Max. lights exceeded")
				var first_light : Light = level.active_lights.pop_front()
				first_light.active = false
				
		else:
			level.active_lights.erase(self)
			inner_material.albedo_color = Color.BLACK

@export var light_color := Color.WHITE :
	set(value):
		color = value
		if omni_light_3d:
			outer_material.albedo_color = value
			omni_light_3d.light_color = value

var hidden := true :
	set(value):
		hidden = value
		body.visible = not value
var target_position : Vector2
var is_selected: bool : set = _set_selected
var is_editing : bool : 
	set(value):
		is_editing = value
		if not value:
			position = Utils.v2_to_v3(target_position)
var is_preview := false 


@onready var omni_light_3d := $OmniLight3D as OmniLight3D
@onready var body = $Body as Node3D
@onready var inner_mesh := %InnerMesh as MeshInstance3D
@onready var inner_material := inner_mesh.get_surface_override_material(0) as StandardMaterial3D
@onready var outer_mesh := %OuterMesh as MeshInstance3D
@onready var outer_material := outer_mesh.get_surface_override_material(0) as StandardMaterial3D
@onready var static_body_3d = $StaticBody3D
@onready var line_renderer_3d := %LineRenderer3D as LineRenderer


func init(_level: Level, _position_2d: Vector2, _properties := {}):
	level = _level
	_init_property_list()
	merge_properties(_properties)
	level.lights_parent.add_child(self)
	position = Vector3(_position_2d.x, 0, _position_2d.y)
	line_renderer_3d.disabled = true
	line_renderer_3d.points.clear()
	line_renderer_3d.points.append_array([Vector3.ZERO, Vector3.UP * 0.75])
	name = "Light"
	return self
	

func _ready() -> void:
	
	# init properties
	property_changed.connect(_on_property_changed)
	update_properties()
	

func _process(delta : float):
	if is_editing:
		target_position = level.ceilling_hovered
		if not Input.is_key_pressed(KEY_CTRL):
			target_position = target_position.snapped(Game.PIXEL_SNAPPING_QUARTER)
	
		if is_preview:
			position = Utils.v2_to_v3(target_position)
		else:
			position = lerp(position, Utils.v2_to_v3(target_position), 10 * delta)
		
	#omni_light_3d.position.y = 0.5 + 1. / 128. * (1 + sin(floor(Time.get_ticks_msec() / PI / 64)))


func _set_selected(value: bool) -> void:
	is_selected = value
	if value:
		line_renderer_3d.disabled = false
		Game.ui.tab_properties.element_selected = self
	else:
		line_renderer_3d.disabled = true
		if Game.ui.tab_properties.element_selected == self:
			Game.ui.tab_properties.element_selected = null


func remove():
	queue_free()


## Properties

const ACTIVE = &"active"
const RANGE = &"show_base"
const COLOR = &"color"


func _init_property_list():
	var init_properties = [
		["", ACTIVE, Property.Hints.BOOL, true],
		["", RANGE, Property.Hints.FLOAT, 5],
		["", COLOR, Property.Hints.COLOR, Color.WHITE],
	]
	for property_array in init_properties:
		init_property(property_array[0], property_array[1], property_array[2], property_array[3])


func _on_property_changed(property_name: String, old_value: Variant, new_value: Variant) -> void:
	match property_name:
		ACTIVE:
			active = new_value
		RANGE:
			range_radius = new_value
		COLOR:
			light_color = new_value

	
###############
# Serializers #
###############

func serialize():
	var serialized_light := {}
	serialized_light["id"] = id
	serialized_light["position"] = Utils.v3_to_a2(position)
	serialized_light["color"] = Utils.color_to_string(color)
	return serialized_light
