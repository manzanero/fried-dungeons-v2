class_name ServerButton
extends PanelContainer


@onready var icon: TextureRect = %IconTexture
@onready var name_label: Label = %NameLabel
@onready var host_label: Label = %HostLabel
@onready var user_label: Label = %UserLabel
@onready var button: Button = %Button


var slug: String
var label: String
var host: String
var username: String
var texture: Texture2D


func init(parent: Control, _slug: String, _label: String, _host: String, _username: String, _texture: Texture2D):
	slug = _slug
	label = _label
	host = _host
	username = _username
	texture = _texture
	parent.add_child(self)
	
	icon.texture = texture
	name_label.text = label
	host_label.text = host
	user_label.text = username

	return self
