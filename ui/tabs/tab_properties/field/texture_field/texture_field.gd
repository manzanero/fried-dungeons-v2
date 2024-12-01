class_name TextureField
extends PropertyField


var property_value: String :
	set(value): 
		property_value = value
		if value:
			texture_button.visible = true
			texture_button.tooltip_text = property_value
			empty_texture_button.visible = false
		else:
			texture_button.visible = false
			empty_texture_button.visible = true


@onready var texture_button: Button = %TextureButton
@onready var empty_texture_button: Button = %EmptyTextureButton
@onready var import_button: Button = %ImportButton
@onready var clear_button: Button = %ClearButton


func set_param(_param_name: String, _param_value: Variant):
	pass


func set_value(_value: Variant):
	property_value = _value


func _ready() -> void:
	empty_texture_button.pressed.connect(_on_empty_texture_button_pressed)
	texture_button.pressed.connect(_on_texture_button_pressed)
	import_button.pressed.connect(_on_import_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	
	
func _on_empty_texture_button_pressed():
	Game.ui.tab_resources.visible = true
	
	
func _on_texture_button_pressed():
	Game.ui.tab_resources.visible = true
	var resource_item := Game.ui.tab_resources.resource_items.get(property_value) as TreeItem
	resource_item.uncollapse_tree()
	resource_item.select(0)
	var tree := resource_item.get_tree()
	tree.item_activated.emit()
	
	var resource: CampaignResource = resource_item.get_metadata(0)
	Debug.print_info_message("Resource \"%s\" edited" % resource.path)


func _on_import_button_pressed():
	var resource: CampaignResource = Game.ui.tab_resources.resource_selected
	if not resource or resource.resource_type != CampaignResource.Type.TEXTURE:
		Utils.temp_tooltip("Select a Texture", 1, true)
		return
		
	property_value = Game.ui.tab_resources.resource_selected.path
	value_changed.emit(property_name, property_value)
	

func _on_clear_button_pressed():
	property_value = ""
	value_changed.emit(property_name, property_value)
