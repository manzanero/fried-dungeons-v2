class_name Level
extends Node3D


signal ground_hitted()


@export var map: Map

@export var walls_parent: Node3D
@export var lights_parent: Node3D
@export var entities_parent: Node3D

@export var selector: Selector


var rect : Rect2 : 
	set(value):
		rect = value
		viewport_3d.rect = value
	get:
		return viewport_3d.rect

var is_ground_hovered : bool
var position_hovered : Vector2
var ceilling_hovered : Vector2
var tile_hovered : Vector2i
var selected_wall : Wall
var selected_light : Light
var selected_entity : Entity
var follower_entity : Entity :
	set(value):
		if follower_entity:
			follower_entity.sprite_mesh.visible = true
		follower_entity = value
		if follower_entity:
			follower_entity.sprite_mesh.visible = false
			follower_entity.is_edit_mode = false
			map.camera.target_position.global_position = follower_entity.global_position
			map.camera.is_fps = true
			
var active_lights : Array[Light] = []


@onready var state_machine: StateMachine = $StateMachine
@onready var viewport_3d := %Viewport3D as Viewport3D
@onready var floor_2d := %Floor2D as Floor2D
@onready var ceilling_mesh_instance_3d: MeshInstance3D = $Ceilling/MeshInstance3D


func init(_map : Map):
	map = _map
	map.selected_level = self
	map.levels_parent.add_child(self)
	return self


func _ready():
	map.camera.changed.connect(_on_camera_changed)
	map.camera.fps_enabled.connect(func (value):
		if value:
			ceilling_mesh_instance_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		else:
			ceilling_mesh_instance_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			follower_entity = null
	)
	ceilling_mesh_instance_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY


func _on_camera_changed():
	if follower_entity:
		follower_entity.global_position = Game.camera.hint_3d.global_position


func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_DELETE) and is_instance_valid(selected_wall):
		selected_wall.remove()


#########
# input #
#########

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Debug.print_message(Debug.DEBUG, "Tile clicked: %s" % tile_hovered)
