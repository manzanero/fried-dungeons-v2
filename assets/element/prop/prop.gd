class_name Prop
extends Element

const SCENE := preload("res://assets/element/prop/prop.tscn")

const SHAPE_SLICE := preload("res://assets/element/prop/shape_slice/shape_slice.tscn")

@export var slices_parent: Node3D
@export var material: ShaderMaterial


var cached_light: Color
var body_color: Color :
	set(value): body_color = value; material.set_shader_parameter("albedo", body_color)
var transparency := 0. : 
	set(value): transparency = value; material.set_shader_parameter("transparency", transparency)
var luminance: float :
	get: return cached_light.v
var is_watched: bool : 
	get: return cached_light.a


# properties
var light_active := true :
	set(value): light_active = value; omni_light_3d.visible = value; ligth_mesh.visible = value
var light_range := 5.0 :
	set(value): light_range = value; omni_light_3d.omni_range = value
var light_color := Color.WHITE :
	set(value):
		light_color = value
		ligth_mesh.material_override.albedo_color = value
		omni_light_3d.light_color = value
var show_label: bool :
	set(value): show_label = value; canvas_layer.visible = value
var texture_resource_path := "" : set = _set_texture_resource_path
var frame := 0 :
	set(value): frame = value; dirty_mesh = true
var shape_scale := 1.0 :
	set(value): shape_scale = value; dirty_mesh = true
var hidden: bool :
	set(value): hidden = value; slices_parent.visible = not value
var is_solid: bool:
	set(value): is_solid = value; set_collision_mask_value(1, value); set_collision_layer_value(1, value)
var is_opaque: bool  # TODO


var texture_resource: CampaignResource
var texture_attributes := {}

var dirty_light := false
var dirty_mesh := false
var selector_disabled := false : set = _set_selector_disabled


@onready var selector_mesh_instance: MeshInstance3D = %SelectorMeshInstance
@onready var collider: CollisionShape3D = %CollisionShape3D
@onready var collider_shape: BoxShape3D = collider.shape
@onready var ligth_mesh: MeshInstance3D = %LigthMesh
@onready var omni_light_3d: OmniLight3D = %OmniLight3D
@onready var canvas_layer: CanvasLayer = %CanvasLayer
@onready var info: Control = %Info
@onready var label_label: Label = %LabelLabel


## properties
const LABEL := "label"
const DESCRIPTION := "description"
const COLOR := "color"
const BLUEPRINT := "blueprint"
const LIGHT_ACTIVE = "light_active"
const LIGHT_RANGE = "light_range"
const LIGHT_COLOR = "light_color"
const SOLID := "solid"
const SHOW_LABEL := "show label"
const HIDDEN := "hidden"
const SCALE := "scale"
const TEXTURE := "texture"
const FRAME := "frame"
const OPAQUE := "opaque"

const prop_init_properties = {
	LABEL: {
		"container": "",
		"hint": Hint.STRING,
		"params": {},
		"default": "Prop Unknown",
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
	LIGHT_ACTIVE: {
		"container": "light",
		"hint": Hint.BOOL,
		"params": {},
		"default": false,
	},
	LIGHT_RANGE: {
		"container": "light",
		"hint": Hint.FLOAT,
		"params":  {
			"suffix": "u",
			"has_slider": true,
			"has_arrows": true,
			"min_value": 1,
			"max_value": 10,
			"step": 1,
		},
		"default": 5,
	},
	LIGHT_COLOR: {
		"container": "light",
		"hint": Hint.COLOR,
		"params": {},
		"default": Color.WHITE,
	},
	#OPAQUE: {
		#"container": "light",
		#"hint": Hint.BOOL,
		#"params": {},
		#"default": true,
	#},
	SOLID: {
		"container": "physics",
		"hint": Hint.BOOL,
		"params": {},
		"default": true,
	},
	SHOW_LABEL: {
		"container": "graphics",
		"hint": Hint.BOOL,
		"params": {},
		"default": false,
	},
	HIDDEN: {
		"container": "graphics",
		"hint": Hint.BOOL,
		"params": {},
		"default": false,
	},
	TEXTURE: {
		"container": "graphics",
		"hint": Hint.TEXTURE,
		"params": {},
		"default": "",
	},
	FRAME: {
		"container": "graphics",
		"hint": Hint.INTEGER,
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
		"hint": Hint.FLOAT,
		"params":  {
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
}

func _ready() -> void:
	type = "prop"
	init_properties = prop_init_properties
	
	snapping = Game.U
	selector_mesh_instance.visible = false
	
	element_velocity = 5
	
	cached_light = level.get_light(position_2d)
	level.light_texture_updated.connect(_on_light_texture_updated)
	
	collider.disabled = true
	map.darkvision_enabled.connect(func (_value):
		cached_light = level.get_light(position_2d)
		update_light()
	)


static func parse_property_values(property_values: Dictionary) -> Dictionary:
	var raw_property_values := {}
	for property_name in property_values:
		if not prop_init_properties.has(property_name):  # to keep compatibility
			continue
		var property_value: Variant = property_values[property_name]
		var init_property_data: Dictionary = prop_init_properties[property_name]
		raw_property_values[property_name] = get_raw_property(init_property_data.hint, property_value)
	return raw_property_values


static func parse_raw_property_values(raw_property_values: Dictionary) -> Dictionary:
	var property_values := {}
	for property_name in raw_property_values:
		if not prop_init_properties.has(property_name):  # to keep compatibility
			continue
		var raw_property_value: Variant = raw_property_values[property_name]
		var init_property_data: Dictionary = prop_init_properties[property_name]
		property_values[property_name] = set_raw_property(init_property_data.hint, raw_property_value)
	return property_values


func change_property(property_name: String, new_value: Variant) -> void:
	match property_name:
		
		# element properties
		LABEL: label = new_value; label_label.text = new_value
		DESCRIPTION: description = new_value
		COLOR:
			color = new_value
			label_label.label_settings.font_color = new_value
			label_label.label_settings.outline_color = Utils.get_outline_color(new_value)
		BLUEPRINT: _set_blueprint(new_value)

		# prop properties
		LIGHT_ACTIVE: light_active = new_value
		LIGHT_RANGE: light_range = new_value
		LIGHT_COLOR: light_color = new_value
		OPAQUE: is_opaque = new_value
		SOLID: is_solid = new_value
		SHOW_LABEL: show_label = new_value
		HIDDEN: hidden = new_value
		TEXTURE: texture_resource_path = new_value
		FRAME: frame = new_value
		SCALE: shape_scale = clamp(new_value, 0.125, 64)
	
	
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


func _on_light_texture_updated():
	var ligth := level.get_light(position_2d)
	if ligth != cached_light:
		cached_light = ligth
		update_light()
		
	if dirty_mesh:
		update_mesh()
		
		
func _process(_delta: float) -> void:
	if show_label and is_watched:
		if level.map.camera.is_fps:
			info.visible = false
		else:
			info.visible = not level.map.camera.eyes.is_position_behind(position)
			const unproject_correction := Vector3.UP * 0.001  # x axis points cannot be unproject
			info.position = level.map.camera.eyes.unproject_position(position + unproject_correction)


func update():
	update_mesh()
	update_light()


func update_light():
	dirty_light = false
	
	if is_watched:
		material.set_shader_parameter("light", cached_light)
	else:
		material.set_shader_parameter("light", Color.TRANSPARENT)
		info.visible = false


func update_mesh():
	dirty_mesh = false
	
	Utils.queue_free_children(slices_parent)
	
	#if not texture_resource or not FileAccess.file_exists(texture_resource.abspath):
		#collider.disabled = true
		#return
	
	var texture: Texture2D
	if texture_resource and FileAccess.file_exists(texture_resource.abspath):
		texture = Utils.png_to_texture(texture_resource.abspath)
	if not texture:
		texture = preload("res://resources/icons/stop_icon.png")  #preload("res://resources/icons/godot_icon.png")
		texture_attributes.get_or_add("scale", 0.5)
		
	material.set_shader_parameter("texture_albedo", texture)
		
	var size: Vector2 = Utils.a2_to_v2(texture_attributes.size) if "size" in texture_attributes else texture.get_size()
	var frames: int = texture_attributes.get("frames", ImportTexture.SLICED_SHAPE_DEFAULTS.frames)
	var effective_frame := clampi(frame, 0, frames - 1)
	var slices: int = texture_attributes.get("slices", ImportTexture.SLICED_SHAPE_DEFAULTS.slices)
	var thickness: int = texture_attributes.get("thickness", ImportTexture.SLICED_SHAPE_DEFAULTS.thickness)
	var direction: String = texture_attributes.get("direction", ImportTexture.SLICED_SHAPE_DEFAULTS.direction)

	var texture_scale: float = texture_attributes.get("scale", ImportTexture.SLICED_SHAPE_DEFAULTS.scale)
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
		
	Debug.print_info_message("Mesh of prop \"%s\" updated" % id)


func _set_selector_disabled(value: bool) -> void:
	for slice in slices_parent.get_children():
		slice.collider.get_child(0).disabled = value
		

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
		"type": type,
		"id": id,
		"position": Utils.v3_to_a2(global_position),
		"rotation": snappedf(rotation_y, 0.001),
		"properties": values,
	}
