class_name Camera
extends Node3D


signal changed()
signal fps_enabled(value : bool)


@export var init_x: float = 15
@export var init_z: float = 25
@export var init_rot_x: float = -60
@export var init_rot_y: float = 0
@export var init_zoom: float = 20

@export var move_speed: float = 1
@export var rot_x_speed: float = 1
@export var rot_y_speed: float = 1
@export var zoom_step: float = 1

@export var min_x: float = -100
@export var max_x: float = 10000
@export var min_z: float = -100
@export var max_z: float = 10000
@export var min_rot_x: float = -90
@export var max_rot_x: float = 90
@export var min_zoom: float = 0
@export var max_zoom: float = 100
@export var is_ortogonal : bool = false : 
	set(value):
		is_ortogonal = value
		if eyes:
			if is_ortogonal:
				eyes.projection = Camera3D.PROJECTION_ORTHOGONAL
			else:
				eyes.projection = Camera3D.PROJECTION_PERSPECTIVE

var is_fps : bool
var is_mouse_visible := true
var is_windows_focused := true
var offset_mouse_move: Vector2
var is_rotate: bool
var is_move: bool
var new_rotation: Vector3
var new_position: Vector3
var floor_level: float = 0.5
var zoom: float = 1.0
var fov: float = 30.0
var floor_projection := Vector3.ZERO


var _has_changed : bool


@onready var focus := $Focus as Marker3D
@onready var pivot := $Focus/Pivot as Marker3D
@onready var eyes := $Focus/Pivot/Camera3D as Camera3D
@onready var hit_marker_2d := %HitMarker2D as ColorRect
@onready var hit_marker_3d := %HitMarker3D as MeshInstance3D
@onready var hit_marker_3d_material := hit_marker_3d.get_surface_override_material(0) as StandardMaterial3D


func _ready():
	new_position = Vector3(init_x, focus.transform.origin.y, init_z)
	new_rotation.x = clamp(deg_to_rad(init_rot_x), deg_to_rad(min_rot_x), deg_to_rad(max_rot_x))
	new_rotation.y = deg_to_rad(init_rot_y)
	new_rotation.z = 0
	zoom = clamp(init_zoom, min_zoom, max_zoom)
	hit_marker_2d.visible = false
	hit_marker_3d.visible = true
	eyes.projection = Camera3D.PROJECTION_ORTHOGONAL if is_ortogonal else Camera3D.PROJECTION_PERSPECTIVE


func _process(delta : float):
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir:
		var direction := Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, focus.rotation.y)
		new_position += direction * delta * 2 * (1 + zoom * 0.1)
			
	if is_fps:
		var offset_rot_x := offset_mouse_move.x * 0.004
		var offset_rot_y := offset_mouse_move.y * 0.004
		new_rotation += Vector3(-offset_rot_y * rot_y_speed, -offset_rot_x * rot_x_speed, 0)
		new_rotation.x = clampf(new_rotation.x, deg_to_rad(-90), deg_to_rad(90))
			
		if is_move:
			var direction := Vector3.FORWARD.rotated(Vector3.UP, focus.rotation.y)
			new_position += direction * delta * 2
	
	else:
		if is_rotate:
			var offset_rot_x := offset_mouse_move.x * 0.008
			var offset_rot_y := offset_mouse_move.y * 0.008
			new_rotation += Vector3(-offset_rot_y * rot_y_speed, -offset_rot_x * rot_x_speed, 0)
			var effective_min_rot_x := -90.0 if is_fps else min_rot_x
			var effective_max_rot_x := 90.0 if is_fps else max_rot_x
			new_rotation.x = clampf(new_rotation.x, deg_to_rad(effective_min_rot_x), deg_to_rad(effective_max_rot_x))
		else:
			new_rotation.x = clampf(new_rotation.x, deg_to_rad(min_rot_x), deg_to_rad(max_rot_x))
			new_rotation.x = snappedf(minf(new_rotation.x, -PI / 8), PI / 8)
			new_rotation.y = snappedf(new_rotation.y, PI / 4)

		if is_move:
			var transform_forward := Vector3.FORWARD.rotated(Vector3.UP, focus.rotation.y)
			var transform_left := Vector3.LEFT.rotated(Vector3.UP, focus.rotation.y)
			var offset_move := offset_mouse_move * (0.005 + zoom * 0.002)
			new_position += move_speed * (offset_move.y * transform_forward + offset_move.x * transform_left)
			new_position.x = clampf(new_position.x, min_x, max_x)
			new_position.z = clampf(new_position.z, min_z, max_z)
		
	offset_mouse_move = Vector2.ZERO

	# fov transition
	if not is_fps and zoom <= 0:
		is_fps = true
		fov = 60
		new_rotation.x = 0
		zoom = 0
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		hit_marker_2d.visible = true
		fps_enabled.emit(true)
	if is_fps and zoom > 0:
		is_fps = false
		fov = 30
		new_rotation.x = deg_to_rad(init_rot_x)
		zoom = init_zoom
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		hit_marker_2d.visible = false
		fps_enabled.emit(false)
	
	# focus position
	if not is_equal_approx(focus.position.y, floor_level):
		focus.position.y = floor_level
		_has_changed = true
	if not is_equal_approx(focus.position.x, new_position.x):
		focus.position.x = lerpf(focus.position.x, new_position.x, 10 * delta)
		_has_changed = true
	if not is_equal_approx(focus.position.z, new_position.z):
		focus.position.z = lerpf(focus.position.z, new_position.z, 10 * delta)
		_has_changed = true

	# focus rotation
	if not focus.rotation.is_equal_approx(new_rotation):
		focus.rotation = focus.rotation.lerp(new_rotation, 10 * delta)
		_has_changed = true

	# zoom
	if is_ortogonal:
		if not is_equal_approx(eyes.size, zoom):
			eyes.position.z = 2 + zoom * 2
			eyes.size = lerpf(eyes.size, zoom, 10 * delta)
			_has_changed = true
	else:
		if not is_equal_approx(eyes.position.z, zoom):
			eyes.position.z = lerpf(eyes.position.z, zoom, 10 * delta)
			_has_changed = true
		
	# fov
	if not is_equal_approx(eyes.fov, fov):
		eyes.fov = lerpf(eyes.fov, fov, 10 * delta)
		_has_changed = true
	
	if _has_changed:
		_has_changed = false
		floor_projection = Vector3(eyes.global_position.x, 0, eyes.global_position.z)
		const color = Color(0.75, 0.75, 0.75, 0.5)
		hit_marker_3d_material.albedo_color = hit_marker_3d_material.albedo_color.lerp(color, 10 * delta)
		hit_marker_3d.global_position = Vector3(focus.global_position.x, 0, focus.global_position.z)
		changed.emit()
	else:
		const color = Color(0.75, 0.75, 0.75, 0)
		hit_marker_3d_material.albedo_color = hit_marker_3d_material.albedo_color.lerp(color, 10 * delta)


func _input(event):
	if event is InputEventMouseMotion:
		if not is_mouse_visible:
			return
			
		if is_rotate or is_move or is_fps:
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
		if event.is_pressed() and is_windows_focused:
			if event.button_index == MOUSE_BUTTON_MIDDLE:
				is_rotate = true
				is_move = false
			if event.button_index == MOUSE_BUTTON_RIGHT:
				is_rotate = false
				is_move = true
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom -= zoom_step * (1 + zoom * 0.1)
				zoom = maxf(zoom, 1) if is_ortogonal else maxf(zoom, min_zoom)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom += zoom_step * (1 + zoom * 0.1)
				zoom = minf(zoom, max_zoom)


func _notification(what : int):
	match what:
		NOTIFICATION_WM_MOUSE_EXIT:
			is_mouse_visible = false
		NOTIFICATION_WM_MOUSE_ENTER:
			is_mouse_visible = true
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			is_windows_focused = false
		NOTIFICATION_APPLICATION_FOCUS_IN:
			is_windows_focused = true
		
