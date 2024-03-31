class_name Floor3D
extends Node3D

signal hit_floor()


var position_hovered : Vector2
var is_tile_hovered : bool
var tile_hovered : Vector2i

var floor_ray := PhysicsRayQueryParameters3D.new()


@onready var viewport_3d := %Viewport3D as Viewport3D
@onready var walls_parent := %Walls as Node3D


func _ready():
	hit_floor.connect(_on_hit_floor)
	
	#hit_floor.connect(func():
		#if is_tile_hovered:
			#viewport_3d.tile_map_set_cell(tile_hovered, Vector2i(0, 10))
	#)


func _process(_delta):
	if Input.is_action_pressed("left_click"):
		hit_floor.emit()


func _on_hit_floor():
	is_tile_hovered = false
	var hit_info = Utils.get_raycast_hit(self, Game.camera.eyes, floor_ray, Utils.get_bitmask(1))
	if hit_info:
		position_hovered = Utils.v3_to_v2(hit_info["position"]).snapped(Game.PIXEL)
		tile_hovered = Utils.v2_to_v2i(position_hovered)
		is_tile_hovered = true


#########
# input #
#########

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Debug.print_message(Debug.DEBUG, "Tile clicked: %s" % tile_hovered)
				
	#elif event is InputEventMouseMotion:
		#if _floor_ray_hit():
			#print("Mouse dragged at: ", event.relative)
