class_name Die
extends RigidBody3D

signal stopped

@export var faces := 0
@export var color := Color.WHITE :
	set(value):
		color = value
		material_base.albedo_color = value
		material_digits.albedo_color = Color.BLACK if color.get_luminance() > 0.33 else Color.WHITE
@export var roll_seed := 0
@export var throw_strength := 5.0

var result := 0
var timeout := 5
var linked_d100: Die

@onready var raycasts := %Raycasts.get_children()
@onready var result_timer := get_tree().create_timer(timeout)
@onready var mesh_instance_3d: MeshInstance3D = %MeshInstance3D
@onready var material_base: StandardMaterial3D = mesh_instance_3d.material_override
@onready var material_digits: StandardMaterial3D = material_base.next_pass


func init(parent: Node, _faces, _color, _roll_seed: int, _linked_d100: Die = null):
	faces = _faces
	roll_seed = _roll_seed
	linked_d100 = _linked_d100
	parent.add_child(self)
	color = _color
	#name = Utils.random_string(8, true)
	return self


func _ready() -> void:
	sleeping_state_changed.connect(_on_sleepin_state_changed)
	if linked_d100:
		linked_d100.stopped.connect(_on_sleepin_state_changed)
	
	# prevent stuck die
	result_timer.timeout.connect(func (): 
		if not result: 
			roll()
	)

	roll()

func _on_sleepin_state_changed():
	if not sleeping:
		result_timer.time_left = timeout
		return
	
	if linked_d100 and not linked_d100.result:
		return
	
	for raycast: RayCast3D in raycasts:
		if raycast.is_colliding():
			result = int(str(raycast.name))
			if linked_d100:
				if result == 10:
					result = 0
				result += linked_d100.result
				if result > 100:
					result -= 100

			stopped.emit()
			return

	roll()


func roll(): 
	seed(roll_seed)
	
	# position
	position += Vector3(randf_range(-2, 2), 2, randf_range(-2, 2))
	position = position.snapped(Vector3.ONE)
	
	# rotation
	for axis in PackedVector3Array([Vector3.RIGHT, Vector3.RIGHT, Vector3.FORWARD]):
		transform.basis *= Basis(axis, randf_range(0, 2 * PI))
		
	# force
	var direction := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	angular_velocity = direction * throw_strength * 1.5
	apply_central_impulse(direction * throw_strength * 0.75)
