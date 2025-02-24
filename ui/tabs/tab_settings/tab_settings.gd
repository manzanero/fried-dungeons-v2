class_name TabSettings
extends Control


signal info_changed(label: String, description: String)
#signal ambient_changed(master_view: bool, light: float, color: Color, master_light: float, master_color: Color)


var cached_valid_label: String


# info
@onready var info_container: PropertyContainer = %InfoContainer
@onready var title_field: StringField = %TitleField
@onready var title_edit: LineEdit = title_field.line_edit
@onready var description_field: StringField = %DescriptionField
@onready var description_edit: LineEdit = description_field.line_edit

# info
@onready var atlas_texture_field: TextureField = %AtlasTextureField

# ambient
@onready var ambient_container: PropertyContainer = %AmbientContainer
@onready var ambient_light_field: FloatField = %AmbientLightField
@onready var ambient_light_field_edit: NumberEdit = ambient_light_field.number_edit
@onready var ambient_color_field: ColorField = %AmbientColorField
@onready var ambient_color_button: ColorEdit = ambient_color_field.color_edit
#@onready var master_view_field: BoolField = %MasterViewField
#@onready var master_view_check: CheckBox = master_view_field.check_box
@onready var override_ambient_light_field: BoolField = %OverrideAmbientLightField
@onready var override_ambient_light_check: CheckBox = override_ambient_light_field.check_box
@onready var master_ambient_light_field: FloatField = %MasterAmbientLightField
@onready var master_ambient_light_field_edit: NumberEdit = master_ambient_light_field.number_edit
@onready var override_ambient_color_field: BoolField = %OverrideAmbientColorField
@onready var override_ambient_color_check: CheckBox = override_ambient_color_field.check_box
@onready var master_ambient_color_field: ColorField = %MasterAmbientColorField
@onready var master_ambient_color_button: ColorEdit = master_ambient_color_field.color_edit
@onready var visibility_field: FloatField = %VisibilityField
@onready var visibility_field_edit: NumberEdit = visibility_field.number_edit


func _ready() -> void:
	
	# info
	title_edit.text_changed.connect(_on_info_edited.unbind(1))
	description_edit.text_changed.connect(_on_info_edited.unbind(1))
	
	# graphics
	atlas_texture_field.texture_changed.connect(_on_atlas_texture_changed)
	
	# ambient
	ambient_light_field_edit.value_changed.connect(_on_ambient_edited.unbind(1))
	ambient_color_button.color_changed.connect(_on_ambient_edited.unbind(1))
	#master_view_check.pressed.connect(_on_ambient_edited)
	override_ambient_light_check.pressed.connect(_on_ambient_edited)
	master_ambient_light_field_edit.value_changed.connect(_on_ambient_edited.unbind(1))
	override_ambient_color_check.pressed.connect(_on_ambient_edited)
	master_ambient_color_button.color_changed.connect(_on_ambient_edited.unbind(1))
	visibility_field_edit.value_changed.connect(_on_ambient_edited.unbind(1))


func _on_info_edited():
	var label := title_edit.text.strip_edges()
	
	info_changed.emit(label if label else "Untitled", description_edit.text)


func _on_atlas_texture_changed(_property_name: String, resource_path: String):
	var texture_resource := Game.manager.get_resource(CampaignResource.Type.TEXTURE, resource_path)
	var map := Game.ui.selected_map
	map.atlas_texture_resource = texture_resource
	
	if texture_resource:
		Game.ui.tab_builder.set_atlas_texture_index(map.atlas_texture, texture_resource.attributes)
	else:
		var attributes := {"size": [16, 16], "textures": 64, "frames": 8}
		Game.ui.tab_builder.set_atlas_texture_index(Map.DEFAULT_ATLAS_TEXTURE, attributes)
	
	Game.server.rpcs.change_atlas_texture.rpc(map.slug, resource_path)


func _on_ambient_edited():
	var map := Game.ui.selected_map
	map.override_ambient_light = override_ambient_light_check.button_pressed
	map.override_ambient_color = override_ambient_color_check.button_pressed
	map.ambient_light = ambient_light_field.property_value / 100.0
	map.master_ambient_light = master_ambient_light_field.property_value / 100.0
	map.ambient_color = ambient_color_button.color
	map.master_ambient_color = master_ambient_color_button.color
	map.current_ambient_light = map.ambient_light
	if override_ambient_light_check.button_pressed:
		map.current_ambient_light = map.master_ambient_light
	map.current_ambient_color = map.ambient_color
	if override_ambient_color_check.button_pressed:
		map.current_ambient_color = map.master_ambient_color
	map.visibility = visibility_field.property_value / 100.0
	
	Game.server.rpcs.change_ambient.rpc(map.slug, 
			map.ambient_light,
			map.ambient_color,
			map.master_ambient_light,
			map.master_ambient_color,
			map.visibility)


func reset():
	var map := Game.ui.selected_map
	if not map:
		return
	
	# info
	title_edit.text = Game.ui.selected_map.label
	description_edit.text = Game.ui.selected_map.description
	
	# graphics
	if map.atlas_texture_resource:
		atlas_texture_field.property_value = map.atlas_texture_resource.path
	else:
		atlas_texture_field.property_value = ""
		
	# ambient
	override_ambient_light_check.set_pressed_no_signal(map.override_ambient_light)
	override_ambient_color_check.set_pressed_no_signal(map.override_ambient_color)
	ambient_light_field_edit.set_value_no_signal(map.ambient_light * 100.0)
	master_ambient_light_field_edit.set_value_no_signal(map.master_ambient_light * 100.0)
	ambient_color_button.color = map.ambient_color
	master_ambient_color_button.color = map.master_ambient_color
	visibility_field_edit.set_value_no_signal(map.visibility * 100.0)
