class_name Entity
extends CharacterBody3D


signal editing_enabled(value: bool)


var level: Level

var target_position: Vector3
var is_edit_mode: bool : set = _set_edit_mode
var is_editing: bool : set = _set_editing


@onready var selector_mesh_instance_3d: MeshInstance3D = %SelectorMeshInstance3D
@onready var body: Node3D = $Body
#@onready var sprite_3d: Sprite3D = $Body/Sprite3D
@onready var sprite_mesh: SpriteMeshInstance = $Body/SpriteMeshInstance


func init(_level: Level, position_2d: Vector2):
	level = _level
	level.entities_parent.add_child(self)
	name = "Entity"
	position = Vector3(position_2d.x, 0, position_2d.y)
	return self
	

func _ready() -> void:
	selector_mesh_instance_3d.visible = false


func _physics_process(delta: float) -> void:
	#if following:
		#global_position = following.global_position
		#return
	
	if not is_edit_mode:
		return
	
	if is_editing:
		if Input.is_key_pressed(KEY_CTRL):
			target_position = Utils.v2_to_v3(level.position_hovered)
		else:
			target_position = Utils.v2_to_v3(level.position_hovered.snapped(Game.PIXEL_SNAPPING_QUARTER))
	
	const input_velocity: float = 1000
	var vector_to_target := target_position - position
	if vector_to_target.distance_to(Vector3.ZERO) > Game.U / 64.0:
		var distance_to_target := vector_to_target.length()
		var direction_to_target := vector_to_target.normalized()
		var velocity_to_target := clampf(delta * distance_to_target * input_velocity, 0, 10)
		velocity = direction_to_target * velocity_to_target
		if move_and_slide():
			target_position = position


func _set_edit_mode(value : bool):
	is_edit_mode = value
	if value:
		selector_mesh_instance_3d.visible = true
	else:
		selector_mesh_instance_3d.visible = false


func _set_editing(value : bool) -> void:
	is_editing = value
	editing_enabled.emit(value)
