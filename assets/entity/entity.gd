class_name Entity
extends Element


signal editing_enabled(value: bool)


var level: Level

var target_position: Vector3
var is_edit_mode: bool : set = _set_edit_mode
var is_editing: bool : set = _set_editing


@onready var base_mesh_instance: MeshInstance3D = $Base/MeshInstance3D
@onready var selector_mesh_instance: MeshInstance3D = %SelectorMeshInstance3D
@onready var body: Node3D = $Body
@onready var sprite_3d: Sprite3D = $Body/Sprite3D
@onready var sprite_mesh: SpriteMeshInstance = $Body/SpriteMeshInstance
@onready var eye: Eye = $Eye


func init(_level: Level, position_2d: Vector2, _properties := {}):
	level = _level
	position = Vector3(position_2d.x, 0, position_2d.y)
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
	body.position.y = 1. / 16. + 1. / 128. * (1 + sin(floor(Time.get_ticks_msec() / PI / 64)))


func _physics_process(delta: float) -> void:
	
	if not is_edit_mode:
		return
	
	if is_editing:
		if Input.is_key_pressed(KEY_CTRL):
			target_position = Utils.v2_to_v3(level.position_hovered)
		else:
			target_position = Utils.v2_to_v3(level.position_hovered.snapped(Game.PIXEL_SNAPPING_QUARTER))
	
	const input_velocity: float = 1000
	var vector_to_target := target_position - position
	if not vector_to_target.is_zero_approx():
		var distance_to_target := vector_to_target.length()
		var direction_to_target := vector_to_target.normalized()
		var velocity_to_target := clampf(delta * distance_to_target * input_velocity, 0, 10)
		velocity = direction_to_target * velocity_to_target
		if move_and_slide():
			target_position = position
	else:
		position = target_position


func _set_edit_mode(value: bool) -> void:
	is_edit_mode = value
	if value:
		selector_mesh_instance.visible = true
	else:
		selector_mesh_instance.visible = false


func _set_editing(value: bool) -> void:
	is_editing = value
	editing_enabled.emit(value)


## Properties
const SHOW_LABEL = &"show_label"
const LABEL = &"label"
const SHOW_BASE = &"show_base"
const BASE_COLOR = &"base_color"
const BASE_SIZE = &"base_size"
const SHOW_BODY = &"show_body"
const BODY_SPRITE = &"body_sprite"
const BODY_COLOR = &"body_color"
const BODY_SIZE = &"body_size"


func _init_property_list():
	var init_properties = [
		["", SHOW_LABEL, Property.Hints.BOOL, true],
		["", LABEL, Property.Hints.STRING, "Unknown"],
		["base", SHOW_BASE, Property.Hints.BOOL, true],
		["base", BASE_COLOR, Property.Hints.COLOR, Color.WHITE],
		["base", BASE_SIZE, Property.Hints.FLOAT, 0.5],
		["body", SHOW_BODY, Property.Hints.BOOL, true],
		["body", BODY_SPRITE, Property.Hints.STRING, "None"],
		["body", BODY_COLOR, Property.Hints.COLOR, Color.WHITE],
		["body", BODY_SIZE, Property.Hints.FLOAT, 0.5],
	]
	for property_array in init_properties:
		init_property(property_array[0], property_array[1], property_array[2], property_array[3])


func _on_property_changed(property_name: String, old_value: Variant, new_value: Variant) -> void:
	match property_name:
		SHOW_LABEL:
			pass
		BASE_COLOR:
			base_mesh_instance.get_surface_override_material(0).set_shader_parameter("albedo", new_value)
			color = new_value
			#var tween = get_tree().create_tween()
			#tween.tween_property(base_mesh_instance, "albedo", new_value, 1)
			#tween.tween_property(base_mesh_instance, "albedo", new_value, 1).set_trans(Tween.TRANS_SINE)
