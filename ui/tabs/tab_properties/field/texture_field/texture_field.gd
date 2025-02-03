class_name TextureField
extends PropertyField


static var SCENE := preload("res://ui/tabs/tab_properties/field/texture_field/texture_field.tscn")

signal texture_changed(property_name: String, resource_path: String)


var allowed_imports: PackedStringArray = ["any"]


var property_value: String :
	set(value): 
		property_value = value
		if value:
			texture_button.visible = true
			texture_button.button_pressed = true
			texture_button.tooltip_text = property_value
			empty_texture_button.visible = false
		else:
			texture_button.visible = false
			empty_texture_button.visible = true


@onready var texture_button: DroppableTextureButton = %TextureButton
@onready var empty_texture_button: DroppableTextureButton = %EmptyTextureButton
#@onready var import_button: Button = %ImportButton
@onready var clear_button: Button = %ClearButton


func set_param(param_name: String, param_value: Variant):
	match param_name:
		"allowed_imports": allowed_imports = param_value  # PackedStringArray


func set_value(_value: Variant):
	property_value = _value


func _ready() -> void:
	texture_changed.connect(value_changed.emit)
	
	empty_texture_button.visible = true
	empty_texture_button.pressed.connect(_on_empty_texture_button_pressed)
	texture_button.visible = false
	texture_button.pressed.connect(_on_texture_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	
	empty_texture_button.dropped_texture.connect(_on_dropped_texture)
	texture_button.dropped_texture.connect(_on_dropped_texture)
	
	
func _on_empty_texture_button_pressed():
	Game.ui.tab_resources.visible = true
	var resource: CampaignResource = Game.ui.tab_resources.resource_selected
	if not resource or resource.resource_type != CampaignResource.Type.TEXTURE:
		Utils.temp_error_tooltip("Select a Texture", 1, true)
		return
		
	property_value = Game.ui.tab_resources.resource_selected.path
	texture_changed.emit(property_name, property_value)
	
	
func _on_texture_button_pressed():
	texture_button.button_pressed = true
	Game.ui.tab_resources.visible = true
	var resource_item := Game.ui.tab_resources.resource_items.get(property_value) as TreeItem
	if not resource_item:
		Utils.temp_error_tooltip("File \"%s\" no longer exist" % property_value, 2, true)
		return
		
	resource_item.uncollapse_tree()
	resource_item.select(0)
	var tree := resource_item.get_tree()
	tree.item_activated.emit()
	
	var resource: CampaignResource = resource_item.get_metadata(0)
	Debug.print_info_message("Resource \"%s\" edited" % resource.path)


func _on_clear_button_pressed():
	property_value = ""
	texture_changed.emit(property_name, property_value)


func _on_dropped_texture(texture: CampaignResource) -> void:
	if texture.resource_import_as in allowed_imports or "any" in allowed_imports:
		property_value = texture.path
		texture_changed.emit(property_name, property_value)
	else:
		Utils.temp_error_tooltip("Texture only can be imported as one of these: " + \
			"\n - %s" % "\n - ".join(allowed_imports), 5, true)
