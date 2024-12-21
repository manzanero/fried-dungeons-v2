class_name Shape
extends Element

const SCENE := preload("res://assets/element/shape/shape.tscn")

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
var frame := 0 :
	set(value): frame = value; dirty_mesh = true
var shape_scale := 100.0 :
	set(value): shape_scale = value; dirty_mesh = true
var is_invisible: bool :
	set(value): is_invisible = value; slices_parent.visible = not value
var is_solid: bool:
	set(value): is_solid = value; set_collision_mask_value(1, value); set_collision_layer_value(1, value)
var is_opaque: bool  # TODO


var texture_resource: CampaignResource
var texture_attributes := {}

var dirty_light := false
var dirty_mesh := false


@onready var selector_mesh_instance: MeshInstance3D = %SelectorMeshInstance
@onready var collider: CollisionShape3D = %CollisionShape3D
@onready var collider_shape: BoxShape3D = collider.shape
@onready var canvas_layer: CanvasLayer = %CanvasLayer
@onready var info: Control = %Info
@onready var label_label: Label = %LabelLabel


## properties
const LABEL := "label"
const SHOW_LABEL := "show label"
const COLOR := "color"
const DESCRIPTION := "description"
const SCALE := "scale"
const TEXTURE := "texture"
const FRAME := "frame"
const INVISIBLE := "invisible"
const OPAQUE := "opaque"
const SOLID := "solid"


func _ready() -> void:
	init_properties = {
		LABEL: {
			"container": "info",
			"hint": Property.Hints.STRING,
			"params": {},
			"default": "Shape Unknown",
		},
		SHOW_LABEL: {
			"container": "info",
			"hint": Property.Hints.BOOL,
			"params": {},
			"default": false,
		},
		COLOR: {
			"container": "info",
			"hint": Property.Hints.COLOR,
			"params": {},
			"default": Color.WHITE,
		},
		DESCRIPTION: {
			"container": "info",
			"hint": Property.Hints.STRING,
			"params": {},
			"default": "",
		},
		TEXTURE: {
			"container": "graphics",
			"hint": Property.Hints.TEXTURE,
			"params": {},
			"default": "",
		},
		FRAME: {
			"container": "graphics",
			"hint": Property.Hints.INTEGER,
			"params": {
				"has_arrows": true,
				"min_value": 0,
				"max_value": 64,
				"step": 1,
				"allow_greater": true,
			},
			"default": 0,
		},
		SCALE: {
			"container": "graphics",
			"hint": Property.Hints.FLOAT,
			"params":  {
				"suffix": "%",
				"has_slider": true,
				"has_arrows": true,
				"min_value": 0,
				"max_value": 200,
				"step": 5,
				"allow_greater": true,
			},
			"default": 100.0,
		},
		INVISIBLE: {
			"container": "physics",
			"hint": Property.Hints.BOOL,
			"params": {},
			"default": false,
		},
		SOLID: {
			"container": "physics",
			"hint": Property.Hints.BOOL,
			"params": {},
			"default": true,
		},
		OPAQUE: {
			"container": "physics",
			"hint": Property.Hints.BOOL,
			"params": {},
			"default": true,
		},
	}
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
		SCALE: 
			new_value /= 100
			shape_scale = clamp(new_value, 0.125, 64)
		INVISIBLE: is_invisible = new_value
		OPAQUE: is_opaque = new_value
		SOLID: is_solid = new_value
	
	
func _set_texture_resource_path(_texture_resource_path: String) -> void:
	if not _texture_resource_path:
		if texture_resource: 
			texture_resource.resource_changed.disconnect(_on_texture_resource_changed)
		texture_resource_path = ""
		texture_resource = null
		texture_attributes = {}
		dirty_mesh = true
	
	elif texture_resource_path != _texture_resource_path:
		texture_resource_path = _texture_resource_path
		if texture_resource: 
			texture_resource.resource_changed.disconnect(_on_texture_resource_changed)
		texture_resource = Game.manager.get_resource(CampaignResource.Type.TEXTURE, _texture_resource_path)
		texture_resource.resource_changed.connect(_on_texture_resource_changed)
		texture_attributes = texture_resource.attributes
		dirty_mesh = true


func _on_texture_resource_changed() -> void:
	texture_attributes = texture_resource.attributes
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
		
	var size: Vector2 = Utils.a2_to_v2(texture_attributes.size) if "size" in texture_attributes else texture.get_size()
	var frames: int = texture_attributes.get("frames", ImportTexture.DEFAULT_FRAMES)
	var effective_frame := clampi(frame, 0, frames - 1)
	var slices: int = texture_attributes.get("slices", ImportTexture.DEFAULT_SLICES)
	var thickness: int = texture_attributes.get("thickness", ImportTexture.DEFAULT_THICKNESS)
	var direction: String = texture_attributes.get("direction", ImportTexture.DEFAULT_DIRECTION)

	var texture_scale: float = texture_attributes.get("scale", ImportTexture.DEFAULT_SCALE)
	var total_scale := texture_scale * shape_scale
	var texture_height := size.y * Game.U / total_scale
	var ratio := 1.0 / texture_height
		
	# adjust collider
	collider.disabled = false
	collider.scale = Vector3.ONE * ratio
	match direction:
		"top":
			collider_shape.size.x = size.x * Game.U
			collider_shape.size.y = slices * thickness * Game.U
			collider_shape.size.z = size.y * Game.U
			collider.position.y = 0.5 * slices * thickness * ratio * Game.U
		"front":
			collider_shape.size.x = size.x * Game.U
			collider_shape.size.y = size.y * Game.U
			collider_shape.size.z = slices * thickness * Game.U
			collider.position.y = 0.5 * size.y * ratio * Game.U
		"side":
			collider_shape.size.x = slices * thickness * Game.U
			collider_shape.size.y = size.y * Game.U
			collider_shape.size.z = size.x * Game.U
			collider.position.y = 0.5 * size.y * ratio * Game.U
		
	# create mesh
	slices_parent.scale = Vector3.ONE * ratio
	match direction:
		"top":
			slices_parent.position.z = 0
			slices_parent.position.y = 0.5 * thickness * ratio * Game.U
			slices_parent.rotation.x = -PI / 2
			slices_parent.rotation.y = 0
		"front":
			slices_parent.position.z = (0.5 - 0.5 * slices) * thickness * ratio * Game.U
			slices_parent.position.y = size.y * ratio * Game.U * 0.5
			slices_parent.rotation.x = 0
			slices_parent.rotation.y = 0
		"side":
			slices_parent.position.z = (0.5 - 0.5 * slices) * thickness * ratio * Game.U
			slices_parent.position.y = size.y * ratio * Game.U * 0.5
			slices_parent.rotation.x = 0
			slices_parent.rotation.y = -PI / 2
	for i in range(slices):
		var slice = SHAPE_SLICE.instantiate()
		slices_parent.add_child(slice)
		slice.depth = thickness
		slice.double_sided = true
		slice.pixel_size = Game.U
		slice.texture = texture
		slice.region_enabled = true
		slice.region_rect = Rect2(size.x * effective_frame, size.y * i, size.x, size.y)
		slice.position.z = i * thickness * Game.U
		slice.update_sprite_mesh()
		for mesh in slice.generated_sprite_mesh.meshes:
			slice.mesh = mesh
			slice.collider.set_collision_layer_value(Game.SELECTOR_LAYER, is_selectable)
			slice.collider_shape.shape = slice.mesh.create_trimesh_shape()
			slice.material_override = material
			slice.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		
	Debug.print_info_message("Mesh of Shape \"%s\" updated" % id)


func _set_selectable(value: bool) -> void:
	super._set_selectable(value)
		
	for slice in slices_parent.get_children():
		slice.collider.set_collision_layer_value(Game.SELECTOR_LAYER, value)


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
		"position": Utils.v3_to_a2(global_position),
		"rotation": snappedf(rotation_y, 0.001),
		"properties": values,
	}
