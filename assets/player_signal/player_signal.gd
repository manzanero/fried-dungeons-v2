class_name PlayerSignal
extends Node3D


var level: Level
var position_2d: Vector2
var color: Color

@onready var stick_1: MeshInstance3D = $Stick1
@onready var circle_1: MeshInstance3D = $Circle1
@onready var circle_2: MeshInstance3D = $Circle2
@onready var circle_3: MeshInstance3D = $Circle3
@onready var material: StandardMaterial3D = stick_1.material_override



func init(parent: Node3D, _position_2d: Vector2, _color: Color) -> PlayerSignal:
	level = parent
	position_2d = _position_2d
	color = _color
	parent.add_child(self)
	return self


func _ready() -> void:
	position = Utils.v2_to_v3(position_2d)
	stick_1.visible = true
	circle_1.visible = true
	circle_2.visible = false
	circle_3.visible = false
	material.albedo_color = color
