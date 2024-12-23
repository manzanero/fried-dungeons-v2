class_name AtlasTextureButton
extends Control


signal index_pressed(index: int)


static var SCENE = preload("res://ui/tabs/tab_builder/atlas_texture_button/atlas_texture_button.tscn")


var index := 0
 #texture.region = Rect2(0, index * 16, 16, 16)
var button_pressed := false :
	set(value): button_pressed = value; button.button_pressed = value


@onready var texture_rect: TextureRect = $TextureRect
@onready var button: Button = $Button

#var atlas_texture: AtlasTexture
#var atlas: Texture2D


func init(_parent: Control, _index: int):
	index = _index
	_parent.add_child(self)
	#texture_rect.texture.atlas = atlas_texture
	return self
	

func _ready() -> void:
	#texture = texture_rect.texture
	#atlas = texture.atlas
	
	button.pressed.connect(index_pressed.emit.bind(index))
