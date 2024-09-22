class_name Entity
extends Element

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
	

func _ready() -> void:
	selector_mesh_instance.visible = false
	
	
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


func _set_selected(value: bool) -> void:
	is_selected = value
	if value:
		if is_instance_valid(level.element_selected):
			level.element_selected.is_selected = false
			
		level.element_selected = self
		Game.ui.tab_properties.element_selected = self
	elif Game.ui.tab_properties.element_selected == self:
		Game.ui.tab_properties.element_selected = null
		
	selector_mesh_instance.visible = value


func _set_preview(value: bool) -> void:
	is_preview = value
	if value:
		if multiplayer.is_server():
			transparency = 0.25
		else:
			transparency = 0.25
	else:
		transparency = 0


## Properties
const SHOW_LABEL = "show_label"
const LABEL = "label"
const COLOR = "color"
const SHOW_BASE = "show_base"
const BASE_SIZE = "base_size"
const SHOW_BODY = "show_body"
const BODY_SPRITE = "body_sprite"
const BODY_SIZE = "body_size"


func _init_property_list(_properties):
	var init_properties = [
		["info", LABEL, Property.Hints.STRING, _properties.get(LABEL, "Unknown")],
		["info", SHOW_LABEL, Property.Hints.BOOL, _properties.get(SHOW_LABEL, true)],
		["info", COLOR, Property.Hints.COLOR, _properties.get(COLOR, Color.WHITE)],
		["base", SHOW_BASE, Property.Hints.BOOL, _properties.get(SHOW_BASE, true)],
		["base", BASE_SIZE, Property.Hints.FLOAT, _properties.get(BASE_SIZE, 0.5)],
		["body", SHOW_BODY, Property.Hints.BOOL, _properties.get(SHOW_BODY, true)],
		["body", BODY_SIZE, Property.Hints.FLOAT, _properties.get(BODY_SIZE, 0.5)],
		["body", BODY_SPRITE, Property.Hints.STRING, _properties.get(BODY_SPRITE, "None")],
	]
	for property_array in init_properties:
		init_property(property_array[0], property_array[1], property_array[2], property_array[3])
		change_property(property_array[1], property_array[3])
		
		
func _on_property_changed(property_name: String, _old_value: Variant, new_value: Variant) -> void:
	change_property(property_name, new_value)


func change_property(property_name: String, new_value: Variant) -> void:
	match property_name:
		SHOW_LABEL:
			show_label = new_value
		LABEL:
			label = new_value
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


###############
# Serializing #
###############

func json():
	var values := {}
	for property in properties:
		values[property] = properties[property].get_raw()
	
	return {
		"type": "entity",
		"id": id,
		"position": Utils.v3_to_a2(position),
		"properties": values,
	}
