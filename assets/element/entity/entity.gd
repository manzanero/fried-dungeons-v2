class_name Entity
extends Element

const SHAPE_SLICE := preload("res://assets/element/shape/shape_slice/shape_slice.tscn")

@export var slices_parent: Node3D
@export var material: ShaderMaterial


var cached_light: Color :
	set(value): 
		cached_light = value; 
		base_mesh_instance.material_override.set_shader_parameter("light", cached_light)
		material.set_shader_parameter("light", cached_light)
var base_color: Color :
	set(value): base_color = value; base_mesh_instance.material_override.set_shader_parameter("albedo", base_color)
var body_color: Color :
	set(value): body_color = value; material.set_shader_parameter("albedo", body_color)
var luminance: float :
	get: return cached_light.v
var is_watched: bool : 
	get: return cached_light.a
var transparency := 0. :
	set(value):
		transparency = value
		base_mesh_instance.material_override.set_shader_parameter("transparency", transparency)
		material.set_shader_parameter("transparency", transparency)


## properties
var texture_resource_path := "" : set = _set_texture_resource_path
var frame := BODY_FRAME_DEFAULT_VALUE :
	set(value): frame = value; dirty_mesh = true
var shape_scale := BODY_SCALE_DEFAULT_VALUE :
	set(value): shape_scale = value; dirty_mesh = true
var show_label: bool :
	set(value): show_label = value; label_label.visible = value
var show_base: bool :
	set(value): show_base = value; base_mesh_instance.visible = value


var texture_resource: CampaignResource
var texture_data := {}

var dirty_light := false
var dirty_mesh := false

@onready var collider: CollisionShape3D = %CollisionShape3D
@onready var base: Node3D = $Base
@onready var base_mesh_instance: MeshInstance3D = $Base/MeshInstance3D
@onready var selector_mesh_instance: MeshInstance3D = %SelectorMeshInstance3D
@onready var body: Node3D = $Body
@onready var selector_collider: StaticBody3D = %SelectorCollider
@onready var eye: Eye = $Eye
@onready var info: Control = %Info
@onready var label_label: Label = %LabelLabel


## properties
const LABEL := "label"; const LABEL_DEFAULT_VALUE := "Entity Unknown"
const SHOW_LABEL := "show label"; const SHOW_LABEL_DEFAULT_VALUE := false;
const COLOR := "color"; const COLOR_DEFAULT_VALUE := Color.WHITE
const DESCRIPTION := "description"; const DESCRIPTION_DEFAULT_VALUE := ""
const SHOW_BASE = "show_base"; const SHOW_BASE_DEFAULT_VALUE := true
const BASE_SIZE := "base_size"; const BASE_SIZE_DEFAULT_VALUE := 0.5
const SHOW_BODY = "show_body"; const SHOW_BODY_DEFAULT_VALUE := true
const BODY_SIZE := "body_size"; const BODY_SIZE_DEFAULT_VALUE := 1.0
const BODY_TEXTURE := "body_texture"; const BODY_TEXTURE_DEFAULT_VALUE := ""
const BODY_FRAME := "body_frame"; const BODY_FRAME_DEFAULT_VALUE := 0
const BODY_SCALE := "body_scale"; const BODY_SCALE_DEFAULT_VALUE := 1.0


func _ready() -> void:
	init_properties = [
		["info", LABEL, Property.Hints.STRING, LABEL_DEFAULT_VALUE],
		["info", SHOW_LABEL, Property.Hints.BOOL, SHOW_LABEL_DEFAULT_VALUE],
		["info", COLOR, Property.Hints.COLOR, COLOR_DEFAULT_VALUE],
		["info", DESCRIPTION, Property.Hints.STRING, DESCRIPTION_DEFAULT_VALUE],
		["graphics", BASE_SIZE, Property.Hints.FLOAT, BASE_SIZE_DEFAULT_VALUE],
		["graphics", SHOW_BASE, Property.Hints.BOOL, SHOW_BASE_DEFAULT_VALUE],
		["graphics", BODY_SIZE, Property.Hints.FLOAT, BODY_SIZE_DEFAULT_VALUE],
		["graphics", SHOW_BODY, Property.Hints.BOOL, SHOW_BODY_DEFAULT_VALUE],
		["graphics", BODY_TEXTURE, Property.Hints.TEXTURE, BODY_TEXTURE_DEFAULT_VALUE],
		["graphics", BODY_FRAME, Property.Hints.INTEGER, BODY_FRAME_DEFAULT_VALUE],
		["graphics", BODY_SCALE, Property.Hints.FLOAT, BODY_SCALE_DEFAULT_VALUE],
	]
	selector_mesh_instance.visible = false


func change_property(property_name: String, new_value: Variant) -> void:
	match property_name:
		
		# element properties
		LABEL: label = new_value; label_label.text = new_value
		SHOW_LABEL: show_label = new_value
		COLOR:
			color = new_value
			label_label.label_settings.font_color = new_value
			label_label.label_settings.outline_color = Utils.get_outline_color(new_value)
			base_color = Color(color.r * luminance, color.g * luminance, color.b * luminance, color.a)
		DESCRIPTION: description = new_value

		# shape properties
		BASE_SIZE:
			base_mesh_instance.scale = Vector3(new_value * 2, 1, new_value * 2).clampf(0.5, 10)
			selector_collider.scale = (Vector3.ONE * new_value * 2).clampf(0.5, 10)
			var selector_mesh: TorusMesh = selector_mesh_instance.mesh
			selector_mesh.inner_radius = new_value / 2
			selector_mesh.outer_radius = new_value / 2 + Game.U
		SHOW_BASE: base.visible = new_value
		BODY_SIZE: body.scale = (Vector3.ONE * new_value * 2).clampf(0.5, 10)
		SHOW_BODY: body.visible = new_value
		BODY_TEXTURE: texture_resource_path = new_value
		BODY_FRAME: frame = new_value
		BODY_SCALE: shape_scale = clamp(new_value, 0.125, 64)
	
	
func _set_texture_resource_path(_texture_resource_path: String) -> void:
	if not _texture_resource_path:
		if texture_resource: texture_resource.resource_changed.disconnect(_on_texture_resource_changed)
		texture_resource_path = ""
		texture_resource = null
		texture_data = {}
		dirty_mesh = true
	
	elif texture_resource_path != _texture_resource_path:
		texture_resource_path = _texture_resource_path
		if texture_resource: texture_resource.resource_changed.disconnect(_on_texture_resource_changed)
		texture_resource = Game.manager.get_resource(CampaignResource.Type.TEXTURE, _texture_resource_path)
		texture_resource.resource_changed.connect(_on_texture_resource_changed)
		texture_data = texture_resource.import_data
		dirty_mesh = true


func _on_texture_resource_changed() -> void:
	texture_data = texture_resource.import_data if texture_resource else {}
	dirty_mesh = true


func _process(_delta: float) -> void:
	body.position.y = 1. / 16. + 1. / 128. * (1 + Game.wave_global)

	var ligth = level.get_light(position_2d)
	if ligth != cached_light:
		dirty_light = true
	cached_light = ligth

	if dirty_light:
		update_light()
		dirty_light = false

	if dirty_mesh:
		update_mesh()
		dirty_mesh = false

	if is_watched:
		if show_label:
			if level.map.camera.is_fps:
				info.visible = false
			else:
				info.visible = not level.map.camera.eyes.is_position_behind(position)
				const unproject_correction := Vector3.UP * 0.001  # x axis points cannot be unproject
				info.position = level.map.camera.eyes.unproject_position(position + unproject_correction)


func update_light():
	if is_watched:
		body_color = Color(luminance, luminance, luminance)
		base_color = Color(color.r * luminance, color.g * luminance, color.b * luminance, color.a)
	else:
		body_color = Color.TRANSPARENT
		base_color = Color.TRANSPARENT
		info.visible = false


func update_mesh():
	Utils.queue_free_children(slices_parent)
	
	if not texture_resource or not FileAccess.file_exists(texture_resource.abspath):
		return
		
	var texture := Utils.png_to_texture(texture_resource.abspath)
	material.set_shader_parameter("texture_albedo", texture)
	if not texture:
		return
		
	var size = Utils.a2_to_v2(texture_data.size) if "size" in texture_data else texture.get_size()
	var frames: int = texture_data.get("frames", ImportTexture.DEFAULT_FRAMES)
	var effective_frame = clampi(frame, 0, frames - 1)
	var slices: int = texture_data.get("slices", ImportTexture.DEFAULT_SLICES)
	var depth: int = texture_data.get("depth", ImportTexture.DEFAULT_DEPTH)
	var tilted: bool = texture_data.get("tilted", ImportTexture.DEFAULT_TILTED)

	var total_scale: float = shape_scale * texture_data.get("scale", ImportTexture.DEFAULT_SCALE)
	total_scale = clampf(total_scale, 0.125, 64)

	# create mesh
	slices_parent.scale = Vector3.ONE * total_scale
	if tilted:
		slices_parent.position.z = 0
		slices_parent.position.y = 0.5 * depth * Game.U * total_scale
		slices_parent.rotation.x = -PI / 2
	else:
		slices_parent.position.z = (0.5 - 0.5 * slices) * depth * Game.U * total_scale
		slices_parent.position.y = size.y * 0.5 * Game.U * total_scale
		slices_parent.rotation.x = 0
	for i in range(slices):
		var slice = SHAPE_SLICE.instantiate()
		slices_parent.add_child(slice)
		slice.depth = depth
		slice.double_sided = true
		slice.pixel_size = Game.U
		slice.texture = texture
		slice.region_enabled = true
		slice.region_rect = Rect2(size.x * effective_frame, size.y * i, size.x, size.y)
		slice.position.z = i * depth * Game.U
		slice.update_sprite_mesh()
		slice.mesh = slice.generated_sprite_mesh.meshes[0]
		slice.material_override = material
		slice.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		
	Debug.print_info_message("Mesh of Shape \"%s\" updated" % id)


func _set_selected(value: bool) -> void:
	super._set_selected(value)
		
	selector_mesh_instance.visible = value


func _set_preview(value: bool) -> void:
	super._set_preview(value)
	
	if value:
		transparency = 0.25
	else:
		transparency = 0


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
		"rotation": snappedf(rotation_y, 0.001),
		"properties": values,
	}
