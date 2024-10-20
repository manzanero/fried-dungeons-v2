class_name Shape
extends Element

const SHAPE_SLICE := preload("res://assets/element/shape/shape_slice/shape_slice.tscn")

@export var slices_parent: Node3D
@export var material: ShaderMaterial


var cached_light: Color :
	set(value): cached_light = value; material.set_shader_parameter("light", cached_light)
var body_color: Color :
	set(value): body_color = value; material.set_shader_parameter("albedo", body_color)
var transparency := 0. : 
	set(value): transparency = value; material.set_shader_parameter("transparency", transparency)
var luminance: float :
	get: return cached_light.v
var is_watched: bool : 
	get: return cached_light.a


# properties
var show_label: bool :
	set(value): show_label = value; canvas_layer.visible = value
var texture_resource_path := "" : set = _set_texture_resource_path
var frame := FRAME_DEFAULT_VALUE :
	set(value): frame = value; dirty_mesh = true
var shape_scale := SCALE_DEFAULT_VALUE :
	set(value): shape_scale = value; dirty_mesh = true
var is_invisible: bool :
	set(value): is_invisible = value; slices_parent.visible = not value
var is_solid: bool:
	set(value): is_solid = value; set_collision_mask_value(1, value); set_collision_layer_value(1, value)
var is_opaque: bool  # TODO


var texture_resource: CampaignResource
var texture_data := {}

var dirty_light := false
var dirty_mesh := false


@onready var selector_mesh_instance: MeshInstance3D = %SelectorMeshInstance
@onready var collider: CollisionShape3D = %CollisionShape3D
@onready var collider_shape: BoxShape3D = collider.shape
@onready var canvas_layer: CanvasLayer = %CanvasLayer
@onready var info: Control = %Info
@onready var label_label: Label = %LabelLabel


## properties
const LABEL := "label"; const LABEL_DEFAULT_VALUE := "Shape Unknown"
const SHOW_LABEL := "show label"; const SHOW_LABEL_DEFAULT_VALUE := false
const COLOR := "color"; const COLOR_DEFAULT_VALUE := Color.WHITE
const DESCRIPTION := "description"; const DESCRIPTION_DEFAULT_VALUE := ""
const TEXTURE := "texture"; const TEXTURE_DEFAULT_VALUE := ""
const FRAME := "frame"; const FRAME_DEFAULT_VALUE := 0
const SCALE := "scale"; const SCALE_DEFAULT_VALUE := 1.0
const INVISIBLE := "invisible"; const INVISIBLE_DEFAULT_VALUE := false
const OPAQUE := "opaque"; const OPAQUE_DEFAULT_VALUE := true
const SOLID := "solid"; const SOLID_DEFAULT_VALUE := true


func _ready() -> void:
	init_properties = [
		["info", LABEL, Property.Hints.STRING, LABEL_DEFAULT_VALUE],
		["info", SHOW_LABEL, Property.Hints.BOOL, SHOW_LABEL_DEFAULT_VALUE],
		["info", COLOR, Property.Hints.COLOR, COLOR_DEFAULT_VALUE],
		["info", DESCRIPTION, Property.Hints.STRING, DESCRIPTION_DEFAULT_VALUE],
		["graphics", TEXTURE, Property.Hints.TEXTURE, TEXTURE_DEFAULT_VALUE],
		["graphics", FRAME, Property.Hints.INTEGER, FRAME_DEFAULT_VALUE],
		["graphics", SCALE, Property.Hints.FLOAT, SCALE_DEFAULT_VALUE],
		["physics", INVISIBLE, Property.Hints.BOOL, INVISIBLE_DEFAULT_VALUE],
		["physics", SOLID, Property.Hints.BOOL, SOLID_DEFAULT_VALUE],
		["physics", OPAQUE, Property.Hints.BOOL, OPAQUE_DEFAULT_VALUE],
	]
	snapping = Game.PIXEL
	selector_mesh_instance.visible = false
	collider.disabled = true


func change_property(property_name: String, new_value: Variant) -> void:
	match property_name:
		
		# element properties
		LABEL: label = new_value; label_label.text = new_value
		SHOW_LABEL: show_label = new_value
		COLOR:
			color = new_value
			label_label.label_settings.font_color = new_value
			label_label.label_settings.outline_color = Utils.get_outline_color(new_value)
		DESCRIPTION: description = new_value
		
		# shape properties
		TEXTURE: texture_resource_path = new_value
		FRAME: frame = new_value
		SCALE: shape_scale = clamp(new_value, 0.125, 64)
		INVISIBLE: is_invisible = new_value
		OPAQUE: is_opaque = new_value
		SOLID: is_solid = new_value
	
	
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
		
	if show_label and is_watched:
		if level.map.camera.is_fps:
			info.visible = false
		else:
			info.visible = not level.map.camera.eyes.is_position_behind(position)
			const unproject_correction := Vector3.UP * 0.001  # x axis points cannot be unproject
			info.position = level.map.camera.eyes.unproject_position(position + unproject_correction)


func update_light():
	if is_watched:
		body_color = Color(luminance, luminance, luminance)
	else:
		body_color = Color.TRANSPARENT
		info.visible = false


func update_mesh():
	Utils.queue_free_children(slices_parent)
	
	if not texture_resource or not FileAccess.file_exists(texture_resource.abspath):
		collider.disabled = true
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
		
	# adjust collider
	collider.disabled = false
	collider.scale = Vector3.ONE * total_scale
	if tilted:
		collider_shape.size.x = size.x * Game.U
		collider_shape.size.y = slices * depth * Game.U
		collider_shape.size.z = size.y * Game.U
		collider.position.y = 0.5 * slices * depth * total_scale * Game.U
	else:
		collider_shape.size.x = size.x * Game.U
		collider_shape.size.y = size.y * Game.U
		collider_shape.size.z = slices * depth * Game.U
		collider.position.y = 0.5 * size.y * total_scale * Game.U
		
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
		"type": "shape",
		"id": id,
		"position": Utils.v3_to_a2(position),
		"rotation": snappedf(rotation_y, 0.001),
		"properties": values,
	}
