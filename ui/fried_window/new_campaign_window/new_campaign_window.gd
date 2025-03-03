class_name NewCampaignWindow
extends FriedWindow


signal new_campaign_created(new_campaign_data: Dictionary, steam: bool)


@onready var steam_button: Button = %SteamButton
@onready var enet_button: Button = %EnetButton

@onready var fields: VBoxContainer = %Fields
@onready var error_container: MarginContainer = %ErrorContainer
@onready var error_label: Label = %ErrorLabel
@onready var create_button: Button = %CreateButton

var title_field: StringField
var path_field: StringField
var icon_field: StringField
var master_name_field: StringField
var master_color_field: ColorField
var example_resources_field: BoolField

func _ready() -> void:
	super._ready()
	
	if Game.server.is_steam_ready:
		steam_button.button_pressed = true
	else:
		enet_button.button_pressed = true
		steam_button.disabled = true
		
	create_button.pressed.connect(_on_created_button_pressed)
	
	title_field = StringField.SCENE.instantiate()
	fields.add_child(title_field)
	title_field.label.text = "Title*"
	title_field.line_edit.placeholder_text = "Untitled"
	title_field.line_edit.text_changed.connect(_on_title_field_change)
	
	path_field = StringField.SCENE.instantiate()
	fields.add_child(path_field)
	path_field.label.text = "Path"
	path_field.property_value = "/"
	path_field.line_edit.editable = false
	
	#icon_field = StringField.SCENE.instantiate()
	#fields.add_child(icon_field)
	#icon_field.label.text = "Icon"
	#icon_field.line_edit.placeholder_text = "None"
	
	master_name_field = StringField.SCENE.instantiate()
	fields.add_child(master_name_field)
	master_name_field.label.text = "Master Name"
	master_name_field.line_edit.placeholder_text = "Master"
	
	master_color_field = ColorField.SCENE.instantiate()
	fields.add_child(master_color_field)
	master_color_field.label.text = "Master Color"
	master_color_field.color_edit.color = Color.WHITE
	
	example_resources_field = BoolField.SCENE.instantiate()
	fields.add_child(example_resources_field)
	example_resources_field.label.text = "Example Resources"
	example_resources_field.check_box.button_pressed = true
	
	reset()


func _on_created_button_pressed() -> void:
	var campaign_label := title_field.property_value
	if not campaign_label:
		error_container.visible = true
		error_label.text = "Title is empty"
		return
		
	var campaign_slug := Utils.slugify(campaign_label)
	if DirAccess.dir_exists_absolute("user://campaigns".path_join(campaign_slug)):
		error_container.visible = true
		error_label.text = "Title collides with another campaign"
		return
	
	var master_name := master_name_field.property_value
	if master_name:
		master_name = master_name_field.line_edit.placeholder_text

	var new_campaign_data := {
		"title": campaign_label,
		#"icon": icon_field.property_value,
		"master_name": master_name_field.property_value,
		"master_color": master_color_field.property_value,
		"example_resources": example_resources_field.property_value,
	}
	new_campaign_created.emit(new_campaign_data, steam_button.button_pressed)
	
	reset()
	_on_close_button_pressed()


func _on_title_field_change(new_text: String) -> void:
	path_field.property_value = "/" + Utils.slugify(new_text)


func reset():
	title_field.property_value = ""
	path_field.property_value = "/"
	#icon_field.property_value = ""
	master_name_field.property_value = ""
	master_color_field.property_value = Color.WHITE
	
	error_container.visible = false
