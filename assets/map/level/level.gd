class_name Level
extends Node3D


@export var map: Map

@export var walls_parent: Node3D
@export var lights_parent: Node3D
@export var entities_parent: Node3D

@export var selector: Selector

@export var refresh_light_frecuency := 0.1

var index := 0
var cells := {}

var rect: Rect2i : 
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

@onready var viewport_3d: Viewport3D = %Viewport3D
@onready var floor_viewport := viewport_3d.floor_viewport
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
	
	## if pixel shading
	#RenderingServer.global_shader_parameter_set("light_texture", light_texture)
	
	## if real time
	#light_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	#floor_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	

func _on_refreshed_light():
	
	# if not real time
	light_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	floor_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	light_sample_2d = light_texture.get_image()


func _on_camera_changed():
	if follower_entity:
		follower_entity.global_position = Game.camera.hint_3d.global_position


func get_light(point: Vector2) -> Color:
	if not light_sample_2d:
		return Color.TRANSPARENT
	var pixel_position := (point - Vector2(rect.position)) * 4 
	if pixel_position.x < 0 or pixel_position.x > light_sample_2d.get_width():
		return Color.TRANSPARENT
	if pixel_position.y < 0 or pixel_position.y > light_sample_2d.get_height():
		return Color.TRANSPARENT
	return light_sample_2d.get_pixelv(pixel_position)


func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_DELETE):
		if is_instance_valid(selected_wall):
			selected_wall.remove()
		if is_instance_valid(selected_entity):
			selected_entity.remove()
		if is_instance_valid(selected_light):
			selected_light.remove()


#########
# input #
#########

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Debug.print_debug_message("Tile clicked: %s" % tile_hovered)


###########
# objects #
###########

class Cell:
	var index: int
	var frame: int

	func _init(_index, _frame) -> void:
		index = _index
		frame = _frame
		

###############
# Serializing #
###############

func json() -> Dictionary:
	var pos_x := rect.position.x
	var pos_z := rect.position.y
	var len_x := rect.size.x
	var len_z := rect.size.y
	
	var tiles := []
	tiles.resize(len_z)
	for y in range(len_z):
		var row := []
		row.resize(len_x)
		tiles[y] = row
	for tile in cells:
		var cell: Cell = cells[tile]
		tiles[tile.y - pos_z][tile.x - pos_x] = {"i": cell.index, "f": cell.frame}
		
	var walls := []
	for wall in walls_parent.get_children():
		walls.append(wall.json())
		
	var entities := []
	for entity: Entity in entities_parent.get_children():
		entities.append(entity.json())
		
	var lights := []
	for light: Light in lights_parent.get_children():
		lights.append(light.json())
		
	var objects := []
		
	var level := {
		"rect": {
			"position": Utils.v2_to_a2(rect.position),
			"size": Utils.v2_to_a2(rect.size),
		},
		"tiles": tiles,
		"walls": walls,
		"entities": entities,
		"lights": lights,
		"objects": objects,
	}
	
	return level
