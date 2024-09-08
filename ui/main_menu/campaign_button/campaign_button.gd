class_name CampaignButton
extends PanelContainer


@onready var icon: TextureRect = %IconTexture
@onready var name_label: Label = %NameLabel
@onready var path_label: Label = %PathLabel
@onready var button: Button = %Button


var slug: String
var campaign_path: String
var campaign_label: String


func init(parent: Control, _slug: String):
	slug = _slug
	parent.add_child(self)
	campaign_path = "user://campaigns/%s" % slug
	var campaign_data = Utils.load_json("%s/campaign.json" % campaign_path)
	if not campaign_data:
		campaign_data = {"label": slug}
		
	campaign_label = campaign_data.label
	name_label.text = campaign_label
	path_label.text = "/%s" % slug
	
	var campaign_icon := "user://campaigns/%s/icon.png" % slug
	if FileAccess.file_exists(campaign_icon):
		var image = Image.load_from_file(campaign_icon)
		var texture = ImageTexture.create_from_image(image)
		icon.texture = texture
	else:
		icon.texture = load("res://user/defaults/icon/default.png") as Texture2D
	return self
