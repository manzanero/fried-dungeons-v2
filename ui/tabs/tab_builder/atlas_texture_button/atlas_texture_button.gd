class_name AtlasTextureButton
extends Control


signal pressed(index: int)


const HEIGHT_ATLAS := 64
const WIDTH_ATLAS := 8
const W_UNIT := 1.0 / WIDTH_ATLAS
const H_UNIT := 1.0 / HEIGHT_ATLAS
const PIXEL := Vector2(W_UNIT, H_UNIT) / 16


@export var index := 0 :
	set(value):
		index = value
		texture.region = Rect2(0, index * 16, 16, 16)

@export var button_pressed := false :
	set(value):
		button_pressed = value
		button.button_pressed = value


@onready var texture_rect: TextureRect = $TextureRect
@onready var texture: AtlasTexture = texture_rect.texture
@onready var atlas: Texture2D = texture.atlas
@onready var button: Button = $Button


func init(_parent: Control, _index: int):
	_parent.add_child(self)
	name = Utils.random_string(8, true)
	index = _index
	return self
	

func _ready() -> void:
	button.pressed.connect(func ():
		pressed.emit(index)
	)
