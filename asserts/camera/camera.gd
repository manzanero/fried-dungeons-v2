class_name Camera
extends Node3D


signal changed()


@export var init_x: float = 15
@export var init_z: float = 25
@export var init_rot_x: float = -60
@export var init_rot_y: float = 0
@export var init_zoom: float = 20

@export var move_speed: float = 0.075
@export var rot_x_speed: float = 0.0025
@export var rot_y_speed: float = 0.0075
@export var zoom_step: float = 0.1
@export var zoom_speed: float = 10

@export var min_x: float = -100
@export var max_x: float = 10000
@export var min_z: float = -100
@export var max_z: float = 10000
@export var min_rot_x: float = -90
@export var max_rot_x: float = 90
@export var min_zoom: float = 0
@export var max_zoom: float = 10

var is_action: bool
var is_move: bool
var is_rotate: bool
var new_rotation: Vector3
var new_position: Vector3
var offset_move: Vector2
var offset_wheel: int
var floor_level: float = 0.75
var zoom: float = 1.0

var is_operated : bool

var _has_changed : bool

@onready var focus := $Focus as Marker3D
@onready var pivot := $Focus/Pivot as Marker3D
@onready var eyes := $Focus/Pivot/Camera3D as Camera3D


func _ready():
	new_position = Vector3(init_x, focus.transform.origin.y, init_z)
	new_rotation.x = clamp(deg_to_rad(init_rot_x), deg_to_rad(min_rot_x), deg_to_rad(max_rot_x))
	new_rotation.y = deg_to_rad(init_rot_y)
	new_rotation.z = 0
	zoom = clamp(init_zoom, min_zoom, max_zoom)


func _process(delta):
	if is_rotate:
		new_rotation += Vector3(-offset_move.y * rot_y_speed, -offset_move.x * rot_x_speed, 0)
		new_rotation.x = clamp(new_rotation.x, deg_to_rad(min_rot_x), deg_to_rad(max_rot_x))

	if is_move:
		var transform_forward = Vector3.FORWARD.rotated(Vector3.UP, focus.rotation.y)
		var transform_left = Vector3.LEFT.rotated(Vector3.UP, focus.rotation.y)
		offset_move *= 0.015 * (zoom + 0.5)
		new_position += move_speed * (offset_move.y * transform_forward + offset_move.x * transform_left)
		new_position.x = clamp(new_position.x, min_x, max_x)
		new_position.z = clamp(new_position.z, min_z, max_z)
		
	offset_move = Vector2.ZERO
	
	if not is_equal_approx(focus.position.y, floor_level):
		focus.position.y = floor_level
		_has_changed = true
	
	if not is_equal_approx(focus.position.x, new_position.x):
		focus.position.x = lerp(focus.position.x, new_position.x, zoom_speed * delta)
		_has_changed = true
	
	if not is_equal_approx(focus.position.z, new_position.z):
		focus.position.z = lerp(focus.position.z, new_position.z, zoom_speed * delta)
		_has_changed = true

	if not focus.rotation.is_equal_approx(new_rotation):
		focus.rotation = lerp(focus.rotation, new_rotation, zoom_speed * delta)
		_has_changed = true

	if not is_equal_approx(eyes.position.z, zoom):
		eyes.position.z = lerp(eyes.position.z, zoom, zoom_speed * delta)
		_has_changed = true
	
	if _has_changed:
		_has_changed = false
		changed.emit()


func _input(event):
	if event is InputEventMouseMotion:
		if is_rotate or is_move:
			offset_move += event.relative

	elif event is InputEventMouseButton:
		if event.is_released():
			if event.button_index == MOUSE_BUTTON_MIDDLE:
				is_rotate = false
			if event.button_index == MOUSE_BUTTON_RIGHT:
				is_move = false
				
			if not is_rotate and not is_move:
				is_operated = false


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
				zoom -= zoom_step * (zoom + 0.25)
				zoom = clamp(zoom, min_zoom, max_zoom)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom += zoom_step * (zoom + 0.25)
				zoom = clamp(zoom, min_zoom, max_zoom)


func _notification(what : int):
	match what:
		NOTIFICATION_WM_MOUSE_EXIT:
			is_move = false
			is_rotate = false
		NOTIFICATION_WM_MOUSE_ENTER:
			is_move = false
			is_rotate = false
