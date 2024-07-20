class_name Level
extends Node3D


signal ground_hitted()


var map : Map


var rect : Rect2 : 
	set(value):
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
			Game.camera.target.global_position = follower_entity.global_position
			Game.camera.is_fps = true
			
var active_lights : Array[Light] = []


var level_ray := PhysicsRayQueryParameters3D.new()


@onready var viewport_3d := %Viewport3D as Viewport3D
@onready var ceilling_mesh_instance_3d: MeshInstance3D = $Ceilling/MeshInstance3D
@onready var walls_parent := %Walls as Node3D
@onready var lights_parent := %Lights as Node3D
@onready var entities_parent := %Entities as Node3D


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
	
	#ground_hitted.connect(func():
		#if is_ground_hovered:
			#viewport_3d.tile_map_set_cell(tile_hovered, Vector2i(0, 10))
	#)


func _physics_process(_delta):
	_process_ground_hitted()
	_process_ceilling_hitted()
	_process_light_selection()
	_process_light_movement()
	_process_entity_selection()
	_process_entity_movement()
	_process_entity_follow()
	_process_wall_selection()


func _process_wall_selection():
	if not Input.is_action_just_pressed("left_click") or Game.handled_input:
		return
		
	if not Game.ui.is_mouse_over_map_tab:
		return

	var hit_info = Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, level_ray, Game.WALL_BITMASK)
	if hit_info:
		var wall_hitted := hit_info["collider"].get_parent() as Wall
		
		selected_light = null
		for light in lights_parent.get_children():
			light.is_edit_mode = false
		
		selected_entity = null
		for entity in entities_parent.get_children():
			entity.is_edit_mode = false
			
		wall_hitted.is_edit_mode = true
		selected_wall = wall_hitted
		for wall in walls_parent.get_children():
			if wall != wall_hitted:
				wall.is_edit_mode = false
				
		Game.handled_input = true
				
	elif is_instance_valid(selected_wall):
		selected_wall.is_edit_mode = false
		selected_wall = null
		

func _process_light_selection():
	if not Input.is_action_just_pressed("left_click") or Game.handled_input:
		return
		
	if not Game.ui.is_mouse_over_map_tab:
		return
		
	var hit_info = Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, level_ray, Game.LIGHT_BITMASK)
	if hit_info:
		var light_hitted := hit_info["collider"].get_parent() as Light
		
		light_hitted.is_edit_mode = true
		selected_light = light_hitted
		for light in lights_parent.get_children():
			if light != light_hitted:
				light.is_edit_mode = false
		
		selected_entity = null
		for entity in entities_parent.get_children():
			entity.is_edit_mode = false
		
		selected_wall = null
		for wall in walls_parent.get_children():
			wall.is_edit_mode = false
		
		Game.handled_input = true

	elif is_instance_valid(selected_light):
		selected_light.is_edit_mode = false
		selected_light = null


func _process_light_movement():
	if not selected_light:
		return
		
	if Input.is_action_just_pressed("left_click") and Game.ui.is_mouse_over_map_tab:
		selected_light.is_editing = true
		
	elif Input.is_action_just_released("left_click"):
		selected_light.is_editing = false


func _process_entity_selection():
	if not Input.is_action_just_pressed("left_click") or Game.handled_input:
		return
		
	if not Game.ui.is_mouse_over_map_tab:
		return
	
	var hit_info = Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, level_ray, Game.SELECTOR_BITMASK)
	if hit_info:
		var entity_hitted := hit_info["collider"].get_parent() as Entity
		
		selected_light = null
		for light in lights_parent.get_children():
			light.is_edit_mode = false

		entity_hitted.is_edit_mode = true
		selected_entity = entity_hitted
		for entity: Entity in entities_parent.get_children():
			if entity != entity_hitted:
				entity.is_edit_mode = false
				
		Game.ui.tab_properties.element_selected = entity_hitted
		
		selected_wall = null
		for wall: Wall in walls_parent.get_children():
			wall.is_edit_mode = false
		
		Game.handled_input = true
	
	elif is_instance_valid(selected_entity): 
		selected_entity.is_edit_mode = false
		selected_entity = null
		
		Game.ui.tab_properties.element_selected = null


func _process_entity_movement():
	if not selected_entity:
		return
		
	if Input.is_action_just_pressed("left_click") and Game.ui.is_mouse_over_map_tab:
		selected_entity.is_editing = true
	elif Input.is_action_just_released("left_click"):
		selected_entity.is_editing = false


func _process_entity_follow():
	if not selected_entity:
		return
		
	if Input.is_action_just_pressed("shift_left_click"):
		follower_entity = selected_entity
		selected_entity = null


func _process_ground_hitted():
	is_ground_hovered = false
	if not Input.is_action_pressed("left_click"):
		return
		
	var hit_info = Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, level_ray, Game.GROUND_BITMASK)
	if hit_info:
		position_hovered = Utils.v3_to_v2(hit_info["position"]).snapped(Game.PIXEL)
		tile_hovered = Utils.v2_to_v2i(position_hovered)
		is_ground_hovered = true
		ground_hitted.emit()


func _process_ceilling_hitted():
	if not Input.is_action_pressed("left_click"):
		return
	
	var hit_info = Utils.get_mouse_hit(map.camera.eyes, map.camera.is_fps, level_ray, Game.CEILLING_BITMASK)
	if hit_info:
		ceilling_hovered = Utils.v3_to_v2(hit_info["position"]).snapped(Game.PIXEL)


#########
# input #
#########

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Debug.print_message(Debug.DEBUG, "Tile clicked: %s" % tile_hovered)
