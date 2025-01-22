class_name AtlasTextureButton
extends Control


signal index_pressed(index: int)


static var SCENE = preload("res://ui/tabs/tab_builder/atlas_texture_button/atlas_texture_button.tscn")


var index := 0

var button_pressed := false :
	set(value): 
		button_pressed = value
		button.button_pressed = button_pressed

@onready var texture_rect: TextureRect = $TextureRect
@onready var button: Button = $Button


func init(_parent: Control, _index: int):
	index = _index
	_parent.add_child(self)
	return self
	

func _ready() -> void:
	button.pressed.connect(index_pressed.emit.bind(index))
