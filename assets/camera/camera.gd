class_name Camera
extends Node3D

signal changed()
signal fps_enabled(value : bool)
signal mouse_entered()
signal mouse_exited()

@export var init_x: float = 15
@export var init_z: float = 25
@export var init_rot_x: float = -60
@export var init_rot_y: float = 0
@export var init_zoom: float = 20

@export var move_speed: float = 1
@export var rot_x_speed: float = 1
@export var rot_y_speed: float = 1
@export var zoom_step: float = 1
@export var swing_speed: float = 10

@export var min_x: float = -100
@export var max_x: float = 100
@export var min_z: float = -100
@export var max_z: float = 100
@export var min_rot_x: float = -90
@export var max_rot_x: float = 90
@export var min_zoom: float = 0
@export var max_zoom: float = 100
@export var fp_fov: float = 75
@export var tp_fov: float = 30
@export var allow_fp: bool = true
@export var allow_tp: bool = true
@export var is_orthogonal : bool = false : 
	set(value):
		is_orthogonal = value
		if eyes:
			if is_orthogonal:
				eyes.projection = Camera3D.PROJECTION_ORTHOGONAL
			else:
				eyes.projection = Camera3D.PROJECTION_PERSPECTIVE

@onready var target_position: CharacterBody3D = %TargetPosition
@onready var target_rotation: Marker3D = %TargetRotation
@onready var focus: Marker3D = %Focus
@onready var pivot: Marker3D = %Pivot
@onready var eyes: Camera3D = %Eyes
@onready var focus_hint_2d: Control = %FocusHint2D
@onready var focus_hint_3d: MeshInstance3D = %FocusHint3D
@onready var focus_hint_3d_material: StandardMaterial3D = focus_hint_3d.get_surface_override_material(0)
@onready var collider: CollisionShape3D = %Collider

static var show_focus_point := true
static var mouse_sensibility := 0.5

var is_operated := true
var is_mouse_visible := true
var is_windows_focused := true
var offset_mouse_move: Vector2
var is_rotate: bool
var is_move: bool
var eyes_hight: float = 0.5
var zoom: float = 10.0
var fov: float = 30.0
var floor_projection := Vector3.ZERO

var is_fps : bool : 
	set(value):
		is_fps = value
		if value:
			fov = fp_fov
			target_rotation.rotation.x = 0
			target_position.position.y = eyes_hight
			zoom = 0
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			fov = tp_fov
			target_rotation.rotation.x = deg_to_rad(init_rot_x)
			zoom = init_zoom
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		focus_hint_2d.visible = value
		collider.disabled = not value
		focus_hint_3d.visible = not value
		fps_enabled.emit(value)

var _has_changed : bool

var position_2d := Vector2.ZERO : 
	set(value): 
		target_position.position = Vector3(value.x, eyes_hight, value.y)
		#focus.position = target_position.position
	get: 
		var target_position_3d := target_position.position
		return Vector2(target_position_3d.x, target_position_3d.z)

var position_3d := Vector3.ZERO : 
	set(value): position_2d = Utils.v3_to_v2(value)
	get: return Utils.v2_to_v3(position_2d)

var rotation_3d := Vector3.ZERO : 
	set(value): target_rotation.rotation = value
	get: return target_rotation.rotation


func _ready():
	# init position
	target_position.position = Vector3(init_x, eyes_hight, init_z)
	focus.position = target_position.position
	
	# init rotation
	target_rotation.rotation.x = clampf(deg_to_rad(init_rot_x), deg_to_rad(min_rot_x), deg_to_rad(max_rot_x))
	target_rotation.rotation.x = snappedf(minf(target_rotation.rotation.x, -PI / 8), PI / 8)
	target_rotation.rotation.y = snappedf(deg_to_rad(init_rot_y), PI / 4)
	target_rotation.rotation.z = 0
	pivot.rotation = target_rotation.rotation
	
	# init zoom
	zoom = clampf(init_zoom, min_zoom, max_zoom)
	eyes.position.z = zoom
	
	focus_hint_2d.visible = is_fps
	focus_hint_3d.visible = not is_fps
	collider.disabled = not is_fps
	eyes.projection = Camera3D.PROJECTION_ORTHOGONAL if is_orthogonal else Camera3D.PROJECTION_PERSPECTIVE


func _physics_process(delta: float) -> void:
	if is_fps:
		var offset_rot_x := offset_mouse_move.x * 0.008 * mouse_sensibility
		var offset_rot_y := offset_mouse_move.y * 0.008 * mouse_sensibility
		target_rotation.rotation += Vector3(-offset_rot_y * rot_y_speed, -offset_rot_x * rot_x_speed, 0)
		target_rotation.rotation.x = clampf(target_rotation.rotation.x, deg_to_rad(-90), deg_to_rad(90))
			
		# should I include this in the future?
		if is_move:
			var direction := Vector3.FORWARD.rotated(Vector3.UP, target_rotation.rotation.y)
			target_position.velocity = direction * delta * move_speed * 100
		else:
			target_position.velocity = Vector3.ZERO
	
	else:
		if is_rotate:
			var offset_rot_x := offset_mouse_move.x * 0.016 * mouse_sensibility
			var offset_rot_y := offset_mouse_move.y * 0.016 * mouse_sensibility
			target_rotation.rotation += Vector3(-offset_rot_y * rot_y_speed, -offset_rot_x * rot_x_speed, 0)
			var effective_min_rot_x := -90.0 if is_fps else min_rot_x
			var effective_max_rot_x := 90.0 if is_fps else max_rot_x
			target_rotation.rotation.x = clampf(target_rotation.rotation.x, deg_to_rad(effective_min_rot_x), deg_to_rad(effective_max_rot_x))
		else:
			target_rotation.rotation.x = clampf(target_rotation.rotation.x, deg_to_rad(min_rot_x), deg_to_rad(max_rot_x))
			target_rotation.rotation.x = snappedf(minf(target_rotation.rotation.x, -PI / 8), PI / 8)
			target_rotation.rotation.y = snappedf(target_rotation.rotation.y, PI / 4)

		if is_move:
			var offset_move := Utils.v2_to_v3(-offset_mouse_move) * 2 * mouse_sensibility
			var velocity := offset_move.rotated(Vector3.UP, target_rotation.rotation.y)
			target_position.velocity = velocity * delta * move_speed * (2 + zoom) * 8
		else:
			target_position.velocity = Vector3.ZERO
	
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if not input_dir:
		input_dir = Input.get_vector("key_a", "key_d", "key_w", "key_s")
	if input_dir and is_operated:
		var direction := Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, target_rotation.rotation.y)
		target_position.velocity = direction * delta * (10 + zoom) * 20
		if is_fps:
			target_position.velocity = direction * delta * move_speed * 100
	elif not is_move:
		target_position.velocity = Vector3.ZERO
	
	target_position.move_and_slide()
	offset_mouse_move = Vector2.ZERO


func _process(delta: float) -> void:

	# fov transition
	if allow_fp and not is_fps and zoom <= 0:
		is_fps = true
	if allow_tp and is_fps and zoom > 0:
		is_fps = false
		
	_process_transform(delta)
	
	# fov
	if not is_equal_approx(eyes.fov, fov):
		eyes.fov = lerpf(eyes.fov, fov, swing_speed * delta)
		_has_changed = true
	
	if _has_changed:
		_has_changed = false
		floor_projection = Vector3(eyes.global_position.x, 0, eyes.global_position.z)
		if show_focus_point:
			const color = Color(0.25, 0.25, 0.25, 0.5)
			focus_hint_3d_material.albedo_color = focus_hint_3d_material.albedo_color.lerp(color, swing_speed * delta)
		changed.emit()
	else:
		const color = Color(0.25, 0.25, 0.25, 0)
		focus_hint_3d_material.albedo_color = focus_hint_3d_material.albedo_color.lerp(color, swing_speed * delta)


func _process_transform(delta: float) -> void:
	
	# Focus position
	var distance := focus.position.distance_to(target_position.position)
	if not is_zero_approx(distance):
		var speed = swing_speed * distance * delta
		focus.position = focus.position.move_toward(target_position.position, speed)
		_has_changed = true
		
	# Pivot rotation
	var from_quat = pivot.transform.basis.get_rotation_quaternion()
	var to_quat = target_rotation.transform.basis.get_rotation_quaternion()
	if not from_quat.is_equal_approx(to_quat):
		var max_step = swing_speed * delta * 1.5
		var new_quat = from_quat.slerp(to_quat, max_step)
		pivot.transform.basis = Basis(new_quat)
		_has_changed = true

	# zoom
	if is_orthogonal:
		if not is_equal_approx(eyes.size, zoom):
			eyes.position.z = 2 + zoom * 2
			eyes.size = lerpf(eyes.size, zoom, swing_speed * delta)
			_has_changed = true
	else:
		if not is_equal_approx(eyes.position.z, zoom):
			eyes.position.z = lerpf(eyes.position.z, zoom, swing_speed * delta)
			_has_changed = true


func _input(event):
	if event is InputEventMouseMotion:
		if not is_operated:
			return
	
		if not is_mouse_visible:
			return
			
		if is_rotate or is_move or is_fps:
			var viewport := get_viewport()
			var size: Vector2i = viewport.size
			var mouse_position := viewport.get_mouse_position()
			
			if mouse_position.x < 0:
				mouse_position.x += size.x
				viewport.warp_mouse(mouse_position)
			elif mouse_position.x > size.x:
				mouse_position.x -= size.x
				viewport.warp_mouse(mouse_position)
			
			if event.relative.length() < 256:
				offset_mouse_move += event.relative
			

	elif event is InputEventMouseButton:
		if event.is_released():
			if event.button_index == MOUSE_BUTTON_MIDDLE:
				is_rotate = false
			if event.button_index == MOUSE_BUTTON_RIGHT:
				is_move = false
	
	elif event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed and is_fps:
			zoom += 1


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if not is_operated:
			return
	
		if event.is_pressed() and is_windows_focused:
			
			#prevent move camera while dragging, TODO I want this in build mode?
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				is_rotate = false
				is_move = false
				return
			
			if event.button_index == MOUSE_BUTTON_MIDDLE:
				is_rotate = true
				is_move = false
			if event.button_index == MOUSE_BUTTON_RIGHT:
				is_rotate = false
				is_move = true
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom -= zoom_step * (1 + zoom * 0.1)
				zoom = maxf(zoom, 1) if is_orthogonal else maxf(zoom, min_zoom)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom += zoom_step * (1 + zoom * 0.1)
				zoom = minf(zoom, max_zoom)


func _notification(what : int):
	match what:
		NOTIFICATION_WM_MOUSE_EXIT:
			is_mouse_visible = false
			mouse_exited.emit()
		NOTIFICATION_WM_MOUSE_ENTER:
			is_mouse_visible = true
			mouse_entered.emit()
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			is_windows_focused = false
		NOTIFICATION_APPLICATION_FOCUS_IN:
			is_windows_focused = true
		
