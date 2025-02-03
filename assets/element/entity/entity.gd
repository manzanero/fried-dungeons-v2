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
var frame := 0 :
	set(value): frame = value; dirty_mesh = true
var show_label: bool :
	set(value): show_label = value; label_label.visible = value
var show_base: bool :
	set(value): show_base = value; base_mesh_instance.visible = value


var texture_resource: CampaignResource
var texture_attributes := {}

var dirty_light := false
var dirty_mesh := false
var selector_disabled := false : set = _set_selector_disabled

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
const LABEL := "label"
const DESCRIPTION := "description"
const BLUEPRINT := "blueprint"
const SHOW_LABEL := "show_label"
const SHOW_BODY = "show_body"
const BODY_TEXTURE := "body_texture"
const BODY_FRAME := "body_frame"
const BODY_SIZE := "body_size"
const SHOW_BASE = "show_base"
const BASE_SIZE := "base_size"
const COLOR := "color"



const entity_init_properties = {
	LABEL: {
		"container": "",
		"hint": Hint.STRING,
		"params": {},
		"default": "Entity Unknown",
	},
	DESCRIPTION: {
		"container": "",
		"hint": Hint.STRING,
		"params": {},
		"default": "",
	},
	COLOR: {
		"container": "",
		"hint": Hint.COLOR,
		"params": {},
		"default": Color.WHITE,
	},
	BLUEPRINT: {
		"container": "",
		"hint": Hint.BLUEPRINT,
		"params": {},
		"default": null,
	},
	SHOW_LABEL: {
		"container": "graphics",
		"hint": Hint.BOOL,
		"params": {},
		"default": false,
	},
	SHOW_BODY: {
		"container": "graphics",
		"hint": Hint.BOOL,
		"params": {},
		"default": true,
	},
	BODY_TEXTURE: {
		"container": "graphics",
		"hint": Hint.TEXTURE,
		"params": {},
		"default": "",
	},
	BODY_FRAME: {
		"container": "graphics",
		"hint": Hint.INTEGER,
		"params": {
			"has_arrows": true,
			"min_value": 0,
			"max_value": 64,
			"step": 1,
		},
		"default": 0,
	},
	BODY_SIZE: {
		"container": "graphics",
		"hint": Hint.FLOAT,
		"params": {
			"is_percentage": true,
			"suffix": "%",
			"has_slider": true,
			"has_arrows": true,
			"min_value": 0,
			"max_value": 200,
			"step": 5,
			"allow_greater": true,
		},
		"default": 1.0,
	},
	SHOW_BASE: {
		"container": "graphics",
		"hint": Hint.BOOL,
		"params": {},
		"default": true,
	},
	BASE_SIZE: {
		"container": "graphics",
		"hint": Hint.FLOAT,
		"params": {
			"is_percentage": true,
			"suffix": "%",
			"has_slider": true,
			"has_arrows": true,
			"min_value": 0,
			"max_value": 200,
			"step": 5,
			"allow_greater": true,
		},
		"default": 0.5,
	},
}

func _ready() -> void:
	type = "entity"
	#blueprint_excluded_properties = [LABEL, DESCRIPTION, COLOR]
	init_properties = entity_init_properties
	selector_mesh_instance.visible = false
	cached_light = level.get_light(position_2d)


static func parse_property_values(property_values: Dictionary) -> Dictionary:
	var raw_property_values := {}
	for property_name in property_values:
		var property_value: Variant = property_values[property_name]
		var init_property_data: Dictionary = entity_init_properties[property_name]
		raw_property_values[property_name] = get_raw_property(init_property_data.hint, property_value)
	return raw_property_values


static func parse_raw_property_values(raw_property_values: Dictionary) -> Dictionary:
	var property_values := {}
	for property_name in raw_property_values:
		var raw_property_value: Variant = raw_property_values[property_name]
		var init_property_data: Dictionary = entity_init_properties[property_name]
		property_values[property_name] = set_raw_property(init_property_data.hint, raw_property_value)
	return property_values


func change_property(property_name: String, new_value: Variant) -> void:
	match property_name:
		
		# element properties
		LABEL: label = new_value; label_label.text = new_value
		BLUEPRINT: _set_blueprint(new_value)
		DESCRIPTION: description = new_value
		COLOR:
			color = new_value
			label_label.label_settings.font_color = new_value
			label_label.label_settings.outline_color = Utils.get_outline_color(new_value)
			base_color = Color(color.r * luminance, color.g * luminance, color.b * luminance, color.a)

		# entity properties
		SHOW_LABEL: show_label = new_value
		SHOW_BODY: body.visible = new_value
		BODY_TEXTURE: texture_resource_path = new_value
		BODY_FRAME: frame = new_value
		BODY_SIZE: 
			body.scale = (Vector3.ONE * new_value).clampf(0.1, 64)
			body.scale.x *= -1 if flipped else 1
		SHOW_BASE: base.visible = new_value
		BASE_SIZE:
			base_mesh_instance.scale = Vector3(new_value * 2, 1, new_value * 2).clampf(0.1, 64)
			selector_collider.scale = (Vector3.ONE * new_value * 2).clampf(0.1, 64)
			var selector_mesh: TorusMesh = selector_mesh_instance.mesh
			selector_mesh.inner_radius = new_value / 2
			selector_mesh.outer_radius = new_value / 2 + Game.U
	
	
func _set_blueprint(_blueprint: CampaignBlueprint) -> void:
	if blueprint:
		blueprint.blueprint_changed.disconnect(_on_blueprint_changed)
		blueprint.blueprint_removed.disconnect(_on_blueprint_removed)
	blueprint = _blueprint
	if blueprint:
		blueprint.blueprint_changed.connect(_on_blueprint_changed)
		blueprint.blueprint_removed.connect(_on_blueprint_removed)
	
	
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
		
		# resource missing
		if not texture_resource:
			texture_resource_path = ""
			texture_resource = null
			texture_attributes = {}
			dirty_mesh = true
			return
			
		texture_resource.resource_changed.connect(_on_texture_resource_changed)
		texture_attributes = texture_resource.attributes
		dirty_mesh = true


func _on_texture_resource_changed() -> void:
	texture_attributes = texture_resource.attributes
	dirty_mesh = true


func _process(_delta: float) -> void:
	body.position.y = 1. / 16. + 1. / 128. * (1 + Game.wave_global)

	var ligth = level.get_light(position_2d)
	if ligth != cached_light:
		dirty_light = true
	cached_light = ligth
	
	if dirty_mesh:
		update_mesh()

	if dirty_light:
		update_light()

	if is_watched:
		if show_label:
			if level.map.camera.is_fps:
				info.visible = false
			else:
				info.visible = not level.map.camera.eyes.is_position_behind(position)
				const unproject_correction := Vector3.UP * 0.001  # bug: x axis points cannot be unproject
				info.position = level.map.camera.eyes.unproject_position(position + unproject_correction)

func update():
	update_mesh()
	update_light()


func update_light():
	dirty_light = false
	
	if is_watched:
		body_color = Color(luminance, luminance, luminance)
		base_color = Color(color.r * luminance, color.g * luminance, color.b * luminance, color.a)
	else:
		body_color = Color.TRANSPARENT
		base_color = Color.TRANSPARENT
		info.visible = false


func update_mesh():
	dirty_mesh = false
	dirty_light = true
	
	Utils.queue_free_children(slices_parent)
	
	var texture: Texture2D
	if texture_resource and FileAccess.file_exists(texture_resource.abspath):
		texture = Utils.png_to_texture(texture_resource.abspath)
	if not texture:
		texture = preload("res://resources/icons/entities_white_icon.png")  # preload("res://resources/icons/godot_icon.png")
		texture_attributes.get_or_add("scale", 0.5)
		
	material.set_shader_parameter("texture_albedo", texture)
		
	var size: Vector2 = Utils.a2_to_v2(texture_attributes.size) if "size" in texture_attributes else texture.get_size()
	var frames: int = texture_attributes.get("frames", ImportTexture.SLICED_SHAPE_DEFAULTS.frames)
	var effective_frame := clampi(frame, 0, frames - 1)
	var slices: int = texture_attributes.get("slices", ImportTexture.SLICED_SHAPE_DEFAULTS.slices)
	var thickness: int = texture_attributes.get("thickness", ImportTexture.SLICED_SHAPE_DEFAULTS.thickness)
	var direction: String = texture_attributes.get("direction", ImportTexture.SLICED_SHAPE_DEFAULTS.direction)

	var texture_scale: float = texture_attributes.get("scale", ImportTexture.SLICED_SHAPE_DEFAULTS.scale) 
	var texture_height := size.y * Game.U / texture_scale
	var ratio := 1.0 / texture_height

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
		var slice: ShapeSlice = SHAPE_SLICE.instantiate()
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


func _set_selector_disabled(value: bool) -> void:
	selector_collider.get_child(0).disabled = value
	for slice in slices_parent.get_children():
		slice.collider.get_child(0).disabled = value


func _set_selectable(value: bool) -> void:
	super._set_selectable(value)
		
	selector_collider.set_collision_layer_value(Game.SELECTOR_LAYER, value)
	for slice in slices_parent.get_children():
		slice.collider.set_collision_layer_value(Game.SELECTOR_LAYER, value)

func _set_selected(value: bool) -> void:
	super._set_selected(value)
		
	selector_mesh_instance.visible = value


func _set_flipped(value: bool) -> void:
	super._set_flipped(value)
	
	body.scale.x = -1 if flipped else 1


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
	return {
		"type": type,
		"id": id,
		"position": Utils.v2_to_a2(position_2d),
		"rotation": snappedf(rotation_y, 0.001),
		"flipped": flipped,
		"properties": get_raw_property_values(),
	}
