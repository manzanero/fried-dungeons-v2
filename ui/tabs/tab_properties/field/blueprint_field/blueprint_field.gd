class_name BlueprintField
extends PropertyField


static var SCENE := preload("res://ui/tabs/tab_properties/field/blueprint_field/blueprint_field.tscn")


signal blueprint_changed(property_name: String, blueprint_id: String)
signal blueprint_saved


var allowed_imports: PackedStringArray = ["any"]


var property_value: CampaignBlueprint :
	set(value): 
		property_value = value
		if value:
			blueprint_button.visible = true
			blueprint_button.button_pressed = true
			blueprint_button.tooltip_text = value.path
			empty_blueprint_button.visible = false
			clear_button.visible = true
			save_button.visible = false
		else:
			blueprint_button.visible = false
			blueprint_button.tooltip_text = " "
			empty_blueprint_button.visible = true
			clear_button.visible = false
			save_button.visible = true


@onready var empty_blueprint_button: DroppableBlueprintButton = %EmptyBlueprintButton
@onready var blueprint_button: DroppableBlueprintButton = %BlueprintButton
@onready var clear_button: Button = %ClearButton
@onready var save_button: Button = %SaveButton



func set_param(param_name: String, param_value: Variant):
	match param_name:
		"allowed_imports": allowed_imports = param_value  # PackedStringArray


func set_value(_value: Variant):
	property_value = _value


func _ready() -> void:
	blueprint_changed.connect(value_changed.emit)
	
	empty_blueprint_button.visible = true
	empty_blueprint_button.pressed.connect(_on_empty_blueprint_button_pressed)
	blueprint_button.visible = false
	blueprint_button.pressed.connect(_on_blueprint_button_pressed)
	clear_button.visible = true
	clear_button.pressed.connect(_on_clear_button_pressed)
	save_button.visible = false
	save_button.pressed.connect(blueprint_saved.emit)
	
	blueprint_button.dropped_blueprint.connect(_on_dropped_blueprint)
	empty_blueprint_button.dropped_blueprint.connect(_on_dropped_blueprint)
	
	
func _on_blueprint_button_pressed():
	blueprint_button.button_pressed = true
	Game.ui.tab_blueprints.visible = true
	var blueprint_item := Game.ui.tab_blueprints.blueprint_items.get(property_value.id) as TreeItem
	if not blueprint_item:
		Utils.temp_error_tooltip("Blueprint \"%s\" no longer exist" % property_value.id, 2, true)
		return
		
	blueprint_item.uncollapse_tree()
	blueprint_item.get_tree().deselect_all()
	blueprint_item.select(0)


func _on_empty_blueprint_button_pressed():
	Game.ui.tab_blueprints.visible = true
	var blueprint: CampaignBlueprint = Game.ui.tab_blueprints.blueprint_selected
	var element_type := Game.ui.tab_properties.element_selected.type
	if not blueprint or blueprint.type != element_type:
		Utils.temp_error_tooltip("Select a blueprint of type %s" % element_type.capitalize(), 2, true)
		return
		
	property_value = blueprint
	blueprint_changed.emit(property_name, property_value)
	

func _on_clear_button_pressed():
	property_value = null
	blueprint_changed.emit(property_name, property_value)


func _on_dropped_blueprint(blueprint: CampaignBlueprint) -> void:
	property_value = blueprint
	blueprint_changed.emit(property_name, property_value)
