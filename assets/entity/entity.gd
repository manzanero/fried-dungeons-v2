class_name Entity
extends Element


signal changed()


var level: Level

var target_position: Vector3
var is_selected: bool : set = _set_selected
var is_editing: bool
var is_preview: bool : set = _set_preview

var cached_light: Color

var show_label: bool :
	set(value): label_label.visible = value
	get: return label_label.visible

var show_base: bool :
	set(value): 
		show_base = value
		base_mesh_instance.visible = value

var base_color: Color :
	set(value):
		base_color = value
		base_mesh_instance.material_override.set_shader_parameter("albedo", base_color)
		base_mesh_instance.material_override.set_shader_parameter("light", cached_light)
		base_mesh_instance.material_override.set_shader_parameter("transparency", transparency)

var body_color: Color :
	set(value): 
		body_color = value
		body_mesh_instance.material_override.set_shader_parameter("albedo", body_color)
		body_mesh_instance.material_override.set_shader_parameter("light", cached_light)
		body_mesh_instance.material_override.set_shader_parameter("transparency", transparency)

var luminance: float :
	get: return cached_light.v

var is_watched: bool : 
	get: return cached_light.a

var position_2d: Vector2 :
	get: return Utils.v3_to_v2(position)

var transparency := 0. :
	set(value):
		transparency = value
		base_mesh_instance.material_override.set_shader_parameter("albedo", base_color)
		base_mesh_instance.material_override.set_shader_parameter("light", cached_light)
		base_mesh_instance.material_override.set_shader_parameter("transparency", transparency)
		body_mesh_instance.material_override.set_shader_parameter("albedo", body_color)
		body_mesh_instance.material_override.set_shader_parameter("light", cached_light)
		body_mesh_instance.material_override.set_shader_parameter("transparency", transparency)

var dirty_mesh := true

@onready var base: Node3D = $Base
@onready var base_mesh_instance: MeshInstance3D = $Base/MeshInstance3D
@onready var selector_mesh_instance: MeshInstance3D = %SelectorMeshInstance3D
@onready var body: Node3D = $Body
@onready var sprite_3d: Sprite3D = $Body/Sprite3D
@onready var body_mesh_instance: SpriteMeshInstance = $Body/SpriteMeshInstance
@onready var selector_collider: StaticBody3D = $SelectorCollider
@onready var eye: Eye = $Eye
@onready var info: Control = %Info
@onready var label_label: Label = %LabelLabel


func init(_level: Level, _position_2d: Vector2, _properties := {}):
	level = _level
	position = Vector3(_position_2d.x, 0, _position_2d.y)
	_init_property_list()
	merge_properties(_properties)
	level.entities_parent.add_child(self)
	name = "Entity"
	return self
	

func _ready() -> void:
	selector_mesh_instance.visible = false
	
	# init properties
	property_changed.connect(_on_property_changed)
	update_properties()
	
	
func _process(_delta: float) -> void:
	body.position.y = 1. / 16. + 1. / 128. * (1 + Game.wave_global)
	
	var ligth = level.get_light(position_2d)
	if ligth != cached_light:
		dirty_mesh = true
		
	cached_light = ligth
		
	if is_watched:
		if dirty_mesh:
			base_color = Color(color.r * luminance, color.g * luminance, color.b * luminance, color.a)
			body_color = Color(luminance, luminance, luminance)
		
		if not level.map.camera.is_fps:
			info.visible = not level.map.camera.eyes.is_position_behind(position)
			info.position = level.map.camera.eyes.unproject_position(position + Vector3.UP * 0.001)  # x axis points cannot be unproject
		else:
			info.visible = false
	else:
		if dirty_mesh:
			body_color = Color.TRANSPARENT
			base_color = Color.TRANSPARENT
			
		info.visible = false
	
	dirty_mesh = false
	

func _physics_process(delta: float) -> void:
	if not is_selected:
		return
	
	if is_editing:
		if Input.is_key_pressed(KEY_CTRL):
			target_position = Utils.v2_to_v3(level.position_hovered)
		else:
			target_position = Utils.v2_to_v3(level.position_hovered.snapped(Game.PIXEL_SNAPPING_QUARTER))
	
	if is_preview:
		position = target_position
	else:
		const input_velocity: float = 1000
		var vector_to_target := target_position - position
		if not vector_to_target.is_zero_approx():
			var distance_to_target := vector_to_target.length()
			var direction_to_target := vector_to_target.normalized()
			var velocity_to_target := clampf(delta * distance_to_target * input_velocity, 0, 10)
			velocity = direction_to_target * velocity_to_target
			if velocity and move_and_slide():
				target_position = position
		else:
			position = target_position


func _set_selected(value: bool) -> void:
	is_selected = value
	if value:
		selector_mesh_instance.visible = true
		Game.ui.tab_properties.element_selected = self
	else:
		selector_mesh_instance.visible = false
		if Game.ui.tab_properties.element_selected == self:
			Game.ui.tab_properties.element_selected = null


func _set_preview(value: bool) -> void:
	is_preview = value
	if value:
		transparency = 0.25
	else:
		transparency = 0


func remove():
	queue_free()


## Properties
const SHOW_LABEL = &"show_label"
const LABEL = &"label"
const COLOR = &"color"
const SHOW_BASE = &"show_base"
const BASE_SIZE = &"base_size"
const SHOW_BODY = &"show_body"
const BODY_SPRITE = &"body_sprite"
const BODY_SIZE = &"body_size"


func _init_property_list():
	var init_properties = [
		["info", SHOW_LABEL, Property.Hints.BOOL, true],
		["info", LABEL, Property.Hints.STRING, "Unknown"],
		["info", COLOR, Property.Hints.COLOR, Color.WHITE],
		["base", SHOW_BASE, Property.Hints.BOOL, true],
		["base", BASE_SIZE, Property.Hints.FLOAT, 0.5],
		["body", SHOW_BODY, Property.Hints.BOOL, true],
		["body", BODY_SIZE, Property.Hints.FLOAT, 0.5],
		["body", BODY_SPRITE, Property.Hints.STRING, "None"],
	]
	for property_array in init_properties:
		init_property(property_array[0], property_array[1], property_array[2], property_array[3])


func _on_property_changed(property_name: String, old_value: Variant, new_value: Variant) -> void:
	match property_name:
		SHOW_LABEL:
			show_label = new_value
		LABEL:
			label_label.text = new_value
		COLOR:
			color = new_value
			label_label.label_settings.font_color = new_value
			dirty_mesh = true
		SHOW_BASE:
			base.visible = new_value
		BASE_SIZE:
			base_mesh_instance.scale = Vector3(new_value * 2, 1, new_value * 2).clampf(0.5, 10)
			selector_collider.scale = (Vector3.ONE * new_value * 2).clampf(0.5, 10)
			var selector_mesh: TorusMesh = selector_mesh_instance.mesh
			selector_mesh.inner_radius = new_value / 2
			selector_mesh.outer_radius = new_value / 2 + 0.063
		SHOW_BODY:
			base.visible = new_value
		BODY_SIZE:
			body.scale = (Vector3.ONE * new_value * 2).clampf(0.5, 10)
