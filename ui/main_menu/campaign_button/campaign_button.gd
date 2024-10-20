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
	campaign_path = "user://campaigns".path_join(slug)
	var campaign_data = Utils.load_json(campaign_path.path_join("campaign.json"))
	if not campaign_data:
		campaign_data = {"label": slug}
		
	name_label.text = campaign_data.label
	path_label.text = "/" + slug
	
	var campaign_icon := campaign_path.path_join("icon.png")
	if FileAccess.file_exists(campaign_icon):
		var image = Image.load_from_file(campaign_icon)
		var texture = ImageTexture.create_from_image(image)
		icon.texture = texture
	else:
		icon.texture = load("res://user/defaults/icon/default.png") as Texture2D
		
	return self
