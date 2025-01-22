class_name WallPointSelector
extends Node3D


@onready var point: MeshInstance3D = %Point
@onready var column: MeshInstance3D = %Column
@onready var pointer: Marker3D = %Pointer
@onready var rail: MeshInstance3D = %Rail


func _ready() -> void:
	reset()


func reset():
	point.visible = false
	column.visible = false
	rail.visible = false
