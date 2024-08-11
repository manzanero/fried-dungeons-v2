class_name Floor2D
extends Node2D


@onready var layers := $Layers as Node2D
@onready var tile_map := $Layers/Layer/TileMap as TileMap
@onready var temp_tile_map := $Layers/TempLayer/TileMap as TileMap


func _ready() -> void:
	tile_map.clear()
