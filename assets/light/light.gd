class_name Light
extends Node3D


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


@export var color := Color.WHITE :
	set(value):
		color = value
		if omni_light_3d:
			outer_material.albedo_color = value
			omni_light_3d.light_color = value

var target_position : Vector2
var is_edit_mode : bool
var is_editing : bool : 
	set(value):
		is_editing = value
		if value:
			line_renderer_3d.disabled = false
		else:
			line_renderer_3d.disabled = true
			position = Utils.v2_to_v3(target_position)


@onready var omni_light_3d := $OmniLight3D as OmniLight3D
@onready var body = $Body as Node3D
@onready var inner_mesh := %InnerMesh as MeshInstance3D
@onready var inner_material := inner_mesh.get_surface_override_material(0) as StandardMaterial3D
@onready var outer_mesh := %OuterMesh as MeshInstance3D
@onready var outer_material := outer_mesh.get_surface_override_material(0) as StandardMaterial3D
@onready var static_body_3d = $StaticBody3D
@onready var line_renderer_3d := %LineRenderer3D as LineRenderer


func init(_level : Level, position_2d : Vector2, _range_radius := range_radius, _color := color, _active := active):
	level = _level
	level.lights_parent.add_child(self)
	position = Vector3(position_2d.x, 0, position_2d.y)
	range_radius = _range_radius
	color = _color
	active = _active
	line_renderer_3d.disabled = true
	line_renderer_3d.points.clear()
	line_renderer_3d.points.append_array([Vector3.ZERO, Vector3.UP * 0.5])
	name = "Light"
	return self


func _ready():
	Game.camera.fps_enabled.connect(_on_camera_fps_enabled)


func _on_camera_fps_enabled(value : bool):
	body.visible = not value
	

func _process(delta : float):
	if is_editing:
		target_position = level.ceilling_hovered
		if not Input.is_key_pressed(KEY_CTRL):
			target_position = target_position.snapped(Game.SNAPPING_QUARTER)
		position = lerp(position, Utils.v2_to_v3(target_position), 10 * delta)


###############
# Serializers #
###############

func serialize():
	var serialized_light := {}
	serialized_light["id"] = id
	serialized_light["position"] = Utils.v3_to_array2(position)
	serialized_light["color"] = Utils.color_to_string(color)
	return serialized_light
