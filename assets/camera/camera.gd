class_name Camera
extends Node3D


signal changed()


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

var is_operated : bool
var is_fps : bool
var is_mouse_visible := true
var is_action: bool
var is_move: bool
var is_rotate: bool
var new_rotation: Vector3
var new_position: Vector3
var offset_mouse_move: Vector2
var floor_level: float = 0.5
var zoom: float = 1.0
var fov: float = 30.0
var floor_projection := Vector3.ZERO


var _has_changed : bool
var _cached_rotation : Vector3

@onready var focus := $Focus as Marker3D
@onready var pivot := $Focus/Pivot as Marker3D
@onready var eyes := $Focus/Pivot/Camera3D as Camera3D
@onready var marker := %Marker as ColorRect


func _ready():
	new_position = Vector3(init_x, focus.transform.origin.y, init_z)
	new_rotation.x = clamp(deg_to_rad(init_rot_x), deg_to_rad(min_rot_x), deg_to_rad(max_rot_x))
	new_rotation.y = deg_to_rad(init_rot_y)
	new_rotation.z = 0
	zoom = clamp(init_zoom, min_zoom, max_zoom)
	marker.visible = false


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
			new_rotation.x = clamp(new_rotation.x, deg_to_rad(min_rot_x), deg_to_rad(max_rot_x))
			new_rotation.y = snappedf(new_rotation.y, PI / 4)

		if is_move:
			var transform_forward := Vector3.FORWARD.rotated(Vector3.UP, focus.rotation.y)
			var transform_left := Vector3.LEFT.rotated(Vector3.UP, focus.rotation.y)
			var offset_move := offset_mouse_move * (0.005 + zoom * 0.001)
			new_position += move_speed * (offset_move.y * transform_forward + offset_move.x * transform_left)
			new_position.x = clampf(new_position.x, min_x, max_x)
			new_position.z = clampf(new_position.z, min_z, max_z)
		
	offset_mouse_move = Vector2.ZERO

	# fov transition
	if not is_fps and zoom < 1:
		is_fps = true
		fov = 60
		#_cached_rotation = new_rotation
		new_rotation.x = 0
		zoom = 0
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		marker.visible = true
	elif is_fps and zoom > 0:
		is_fps = false
		fov = 30
		new_rotation.x = deg_to_rad(init_rot_x)
		#new_rotation.y = _cached_rotation.y
		zoom = init_zoom
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		marker.visible = false
	
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
	if not is_equal_approx(eyes.position.z, zoom):
		eyes.position.z = lerpf(eyes.position.z, zoom, 10 * delta)
		_has_changed = true
		
	# fov
	if not is_equal_approx(eyes.fov, fov):
		eyes.fov = lerpf(eyes.fov, fov, 10 * delta)
		_has_changed = true
	
	if _has_changed:
		floor_projection = Vector3(eyes.global_position.x, 0, eyes.global_position.z)
		_has_changed = false
		changed.emit()


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
				
			if not is_rotate and not is_move:
				is_operated = false
	
	elif event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed and is_fps:
			zoom += 1


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_MIDDLE:
				is_operated = true
				is_rotate = true
				is_move = false
			if event.button_index == MOUSE_BUTTON_RIGHT:
				is_operated = true
				is_rotate = false
				is_move = true
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom -= zoom_step * (1 + zoom * 0.1)
				zoom = clamp(zoom, min_zoom, max_zoom)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom += zoom_step * (1 + zoom * 0.1)
				zoom = clamp(zoom, min_zoom, max_zoom)


func _notification(what : int):
	match what:
		NOTIFICATION_WM_MOUSE_EXIT:
			is_mouse_visible = false
		NOTIFICATION_WM_MOUSE_ENTER:
			is_mouse_visible = true
