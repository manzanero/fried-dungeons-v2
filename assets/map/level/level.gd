class_name Level
extends Node3D


@export var map: Map

@export var walls_parent: Node3D
@export var lights_parent: Node3D
@export var entities_parent: Node3D

@export var selector: Selector

@export var refresh_light_frecuency := 0.1


var rect: Rect2 : 
	set(value):
		rect = value
		viewport_3d.rect = value
	get:
		return viewport_3d.rect

var is_ground_hovered: bool
var position_hovered: Vector2
var ceilling_hovered: Vector2
var tile_hovered: Vector2i
var selected_wall: Wall
var selected_light: Light
var selected_entity: Entity
var follower_entity: Entity :
	set(value):
		if follower_entity:
			follower_entity.sprite_mesh.visible = true
		follower_entity = value
		if follower_entity:
			follower_entity.sprite_mesh.visible = false
			follower_entity.is_selected = false
			map.camera.target_position.global_position = follower_entity.global_position
			map.camera.is_fps = true
			
var active_lights: Array[Light] = []

var light_sample_2d: Image


@onready var state_machine: StateMachine = $StateMachine

@onready var viewport_3d := %Viewport3D as Viewport3D
@onready var floor_2d := %Floor2D as Floor2D

@onready var refresh_light_timer: Timer = %RefreshLightTimer
@onready var light_viewport: SubViewport = %LightViewport
@onready var light_texture: ViewportTexture = light_viewport.get_texture()
@onready var camera_3d: Camera3D = %Camera3D

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
	
	refresh_light_timer.wait_time = refresh_light_frecuency
	refresh_light_timer.timeout.connect(_on_refreshed_light)
	RenderingServer.global_shader_parameter_set("light_texture", light_texture)
	#light_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	

func _on_refreshed_light():
	light_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	light_sample_2d = light_texture.get_image()
	
	#for entity: Entity in entities_parent.get_children():
		#if get_light(entity.position_2d).a:
			#entity.is_watched = true
		#else:
			#entity.is_watched = false


func _on_camera_changed():
	if follower_entity:
		follower_entity.global_position = Game.camera.hint_3d.global_position


func get_light(point: Vector2) -> Color:
	if not light_sample_2d:
		return Color.TRANSPARENT
	return light_sample_2d.get_pixelv(point * 16)


func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_DELETE):
		if is_instance_valid(selected_wall):
			selected_wall.remove()
		if is_instance_valid(selected_entity):
			selected_entity.remove()
		if is_instance_valid(selected_light):
			selected_light.remove()
			
	#if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#Debug.print_debug_message(str(get_point_light(position_hovered)))


#########
# input #
#########

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Debug.print_message(Debug.DEBUG, "Tile clicked: %s" % tile_hovered)
