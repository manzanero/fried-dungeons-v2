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
var active_lights : Array[Light] = []


var floor_ray := PhysicsRayQueryParameters3D.new()


@onready var viewport_3d := %Viewport3D as Viewport3D
@onready var walls_parent := %Walls as Node3D
@onready var lights_parent := %Lights as Node3D
@onready var entities_parent := %Entities as Node3D


func init(_map : Map):
	map = _map
	map.selected_level = self
	map.levels_parent.add_child(self)
	return self


#func _ready():
	
	#ground_hitted.connect(func():
		#if is_ground_hovered:
			#viewport_3d.tile_map_set_cell(tile_hovered, Vector2i(0, 10))
	#)


func _physics_process(delta):
	_process_ground_hitted()
	_process_ceilling_hitted()
	_process_light_selection()
	_process_light_movement()
	_process_entity_selection()
	_process_entity_movement()
	_process_wall_selection()


func _process_wall_selection():
	if not Input.is_action_just_pressed("left_click") or Game.handled_input:
		return
		
	var hit_info = Utils.get_mouse_hit(Game.camera.eyes, floor_ray, Game.WALL_BITMASK)
	if hit_info:
		var wall_hitted := hit_info["collider"].get_parent() as Wall
		wall_hitted.is_edit_mode = not wall_hitted.is_edit_mode


func _process_light_selection():
	if not Input.is_action_just_pressed("left_click") or Game.handled_input:
		return
		
	var hit_info = Utils.get_mouse_hit(Game.camera.eyes, floor_ray, Game.LIGHT_BITMASK)
	if hit_info:
		var light_hitted := hit_info["collider"].get_parent() as Light
		light_hitted.is_edit_mode = not light_hitted.is_edit_mode
		if light_hitted.is_edit_mode:
			selected_light = light_hitted
		else:
			selected_light = null
			
		Game.handled_input = true


func _process_light_movement():
	if not selected_light:
		return
		
	if Input.is_action_pressed("left_click"):
		selected_light.is_editing = true
	else:
		selected_light.is_editing = false
		
		# Remove this when light have edit form
		selected_light.is_edit_mode = false
		selected_light = null


func _process_entity_selection():
	if not Input.is_action_just_pressed("left_click") or Game.handled_input:
		return
		
	var hit_info = Utils.get_mouse_hit(Game.camera.eyes, floor_ray, Game.ENTITY_BITMASK)
	if hit_info:
		var entity_hitted := hit_info["collider"].get_parent() as Entity
		entity_hitted.is_edit_mode = not entity_hitted.is_edit_mode
		if entity_hitted.is_edit_mode:
			selected_entity = entity_hitted
		else:
			selected_entity = null
			
		Game.handled_input = true


func _process_entity_movement():
	if not selected_entity:
		return
		
	if Input.is_action_pressed("left_click"):
		selected_entity.is_editing = true
	else:
		selected_entity.is_editing = false
		
		# Remove this when entity have edit form
		selected_entity.is_edit_mode = false
		selected_entity = null
		

func _process_ground_hitted():
	if not Input.is_action_pressed("left_click"):
		return
		
	is_ground_hovered = false
	var hit_info = Utils.get_mouse_hit(Game.camera.eyes, floor_ray, Game.GROUND_BITMASK)
	if hit_info:
		position_hovered = Utils.v3_to_v2(hit_info["position"]).snapped(Game.PIXEL)
		tile_hovered = Utils.v2_to_v2i(position_hovered)
		is_ground_hovered = true
		ground_hitted.emit()


func _process_ceilling_hitted():
	if not Input.is_action_pressed("left_click"):
		return
	
	var hit_info = Utils.get_mouse_hit(Game.camera.eyes, floor_ray, Game.CEILLING_BITMASK)
	if hit_info:
		ceilling_hovered = Utils.v3_to_v2(hit_info["position"]).snapped(Game.PIXEL)


#########
# input #
#########

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Debug.print_message(Debug.DEBUG, "Tile clicked: %s" % tile_hovered)
