class_name Shape
extends Element

const SHAPE_SLICE = preload("res://assets/element/shape/shape_slice/shape_slice.tscn")

const ATLAS := "atlas"
const ATLAS_DEFAULT_VALUE := "bookshelf/bookshelf.png"  # "none"
const FRAMES := "frames"
const FRAMES_DEFAULT_VALUE := 4
const FRAME := "frame"
const FRAME_DEFAULT_VALUE := 1
const SLICES := "slices"
const SLICES_DEFAULT_VALUE := 4
const SCALE := "scale"
const SCALE_DEFAULT_VALUE := 1


@export var slices_parent: Node3D
@export var material: ShaderMaterial

@export var atlas := ATLAS_DEFAULT_VALUE
@export var frames := FRAMES_DEFAULT_VALUE
@export var frame := FRAME_DEFAULT_VALUE
@export var slices := SLICES_DEFAULT_VALUE
@export var shape_scale := SCALE_DEFAULT_VALUE

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


var dirty_light := false
var dirty_mesh := false


@onready var selector_mesh_instance: MeshInstance3D = %SelectorMeshInstance
@onready var collider: CollisionShape3D = %CollisionShape3D
@onready var collider_shape: BoxShape3D = collider.shape


func _ready() -> void:
	snapping = Game.PIXEL
	update_mesh()
	selector_mesh_instance.visible = false


func _init_property_list(_properties):
	var init_properties = [
		["", ATLAS, Property.Hints.STRING, ATLAS_DEFAULT_VALUE],
		["", FRAMES, Property.Hints.INTEGER, FRAMES_DEFAULT_VALUE],
		["", FRAME, Property.Hints.INTEGER, FRAME_DEFAULT_VALUE],
		["", SLICES, Property.Hints.INTEGER, SLICES_DEFAULT_VALUE],
		["", SCALE, Property.Hints.FLOAT, SCALE_DEFAULT_VALUE],
	]
	for property_array in init_properties:
		var value = _properties.get(property_array[1], property_array[3])
		init_property(property_array[0], property_array[1], property_array[2], value)
		change_property(property_array[1], value)


func _on_property_changed(property_name: String, _old_value: Variant, new_value: Variant) -> void:
	change_property(property_name, new_value)
	

func change_property(property_name: String, new_value: Variant) -> void:
	match property_name:
		ATLAS:
			atlas = new_value
			dirty_mesh = true
		FRAMES:
			frames = new_value
			dirty_mesh = true
		FRAME:
			frame = new_value
			dirty_mesh = true
		SLICES:
			slices = new_value
			dirty_mesh = true
		SCALE:
			shape_scale = new_value
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


func update_light():
	if is_watched:
		body_color = Color(luminance, luminance, luminance)
	else:
		body_color = Color.TRANSPARENT


func update_mesh():
	for slice in slices_parent.get_children():
		slice.queue_free()
	#for slice_collider in selector_mesh_instance.get_children():
		#slice_collider.queue_free()
	
	if atlas == 'none':
		return
	
	var atlas_texture := Utils.png_to_texture(Game.campaign.resources_path.path_join(atlas))
	if not atlas_texture:
		material.set_shader_parameter("texture_albedo", null)
		collider.disabled = true
		return

	else:
		material.set_shader_parameter("texture_albedo", atlas_texture)
		collider.disabled = false
	
	# adjust collider
	slices_parent.position.z = -slices / 2.0 * Game.U
	collider_shape.size.z = Game.U * slices
	collider.position.z = 0
	if slices % 2:
		slices_parent.position.z += Game.U / 2
		collider.position.z = Game.U / 2
	collider.position.y = 0.5
	
	for i in range(slices):
		var slice = SHAPE_SLICE.instantiate()
		slices_parent.add_child(slice)
		slice.depth = 1
		slice.double_sided = true
		slice.pixel_size = Game.U
		slice.texture = atlas_texture
		slice.region_enabled = true
		slice.region_rect = Rect2(16 * frame * Vector2.RIGHT + 16 * i * Vector2.DOWN, Vector2(16, 16))
		slice.position.z = i / 16.0 + 1.0 / 32.0
		slice.position.y = slice.texture.get_height() * 0.5 * 1 / 16 / slices
		slice.update_sprite_mesh()
		slice.mesh = slice.generated_sprite_mesh.meshes[0]
		slice.material_override = material
		slice.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		
		#var slice_collider := CollisionShape3D.new()
		#slice_collider.shape = slice.mesh.create_trimesh_shape()
		#selector_mesh_instance.add_child(slice_collider)


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
