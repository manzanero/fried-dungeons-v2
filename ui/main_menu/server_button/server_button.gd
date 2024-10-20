class_name ServerButton
extends PanelContainer


@onready var icon: TextureRect = %IconTexture
@onready var name_label: Label = %NameLabel
@onready var host_label: Label = %HostLabel
@onready var user_label: Label = %UserLabel
@onready var button: Button = %Button


var slug: String
var server_data: Dictionary
var player_data: Dictionary
var texture: Texture2D


func init(parent: Control, _slug: String, _server_data: Dictionary, _player_data: Dictionary, _texture: Texture2D):
	slug = _slug
	server_data = _server_data
	player_data = _player_data
	texture = _texture
	parent.add_child(self)
	
	icon.texture = texture
	name_label.text = server_data.label
	host_label.text = server_data.host
	user_label.text = player_data.username
	
	button.pressed.connect(_on_button_pressed)

	return self


func _on_button_pressed():
	Game.ui.main_menu.host_line_edit.text = server_data.host
	Game.ui.main_menu.username_line_edit.text = player_data.username
	Game.ui.main_menu.password_line_edit.text = player_data.password
	
