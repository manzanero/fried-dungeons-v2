class_name TabProperties
extends Control

@export var settings: TabSettings

var element_selected: Element : set = _set_element_selected
var root_container: PropertyContainer
var containers_tree := {}
var unsaved_blueprints: Array[CampaignBlueprint] = []

@onready var property_containers: VBoxContainer = %PropertyContainers
@onready var element_properties: PanelContainer = $ElementProperties


func _set_element_selected(element: Element):
	Utils.safe_queue_free(root_container)
	containers_tree.clear()
	if not element:
		element_properties.visible = false
		if is_instance_valid(element_selected):
			Debug.print_debug_message("Element \"%s\" unselected" % element_selected.name)
		return
	
	element_properties.visible = true
	element_selected = element
	Debug.print_info_message("Element \"%s\" selected" % element_selected.name) 
		
	root_container = PropertyContainer.SCENE.instantiate().init(property_containers)
	root_container.container_name = element_selected.name
	root_container.collapsable = false
	
	var properties := element_selected.properties
	_make_containers_tree(properties)
	
	for property_name in properties:
		var property: Element.Property = properties[property_name]
		var property_container: PropertyContainer = containers_tree[property.container]
		var field: PropertyField
		match property.hint:
			Element.Hint.STRING:
				field = StringField.SCENE.instantiate().init(property_container, property_name, property)
			Element.Hint.COLOR:
				field = ColorField.SCENE.instantiate().init(property_container, property_name, property)
			Element.Hint.CHOICE:
				field = ChoiceField.SCENE.instantiate().init(property_container, property_name, property)
			Element.Hint.BOOL:
				field = BoolField.SCENE.instantiate().init(property_container, property_name, property)
			Element.Hint.FLOAT:
				field = FloatField.SCENE.instantiate().init(property_container, property_name, property)
			Element.Hint.INTEGER:
				field = IntegerField.SCENE.instantiate().init(property_container, property_name, property)
			Element.Hint.VECTOR_2:
				field = Vector2Field.SCENE.instantiate().init(property_container, property_name, property)
			Element.Hint.TEXTURE:
				field = TextureField.SCENE.instantiate().init(property_container, property_name, property)
			Element.Hint.BLUEPRINT:
				field = BlueprintField.SCENE.instantiate().init(property_container, property_name, property) as BlueprintField
				field.blueprint_changed.connect(_on_blueprint_changed)
				field.blueprint_saved.connect(_on_blueprint_saved)
				continue
			_:
				Debug.print_error_message("Unkown type \"%s\" of property \"%s\"" % [typeof(property.value), property_name]) 
		field.value_changed.connect(_on_field_value_changed)
		
		# custom params, update sliders
		if element is Entity and property_name == "body_frame":
			field.set_param("max_value", element.texture_attributes.get("frames", 1) - 1)
		if element is Prop and property_name == "frame":
			field.set_param("max_value", element.texture_attributes.get("frames", 1) - 1)


func _make_containers_tree(properties: Dictionary):
	containers_tree[""] = root_container
	for property_name in properties:
		var property: Element.Property = properties[property_name]
		var container_name := property.container
		if not containers_tree.has(container_name):
			containers_tree[container_name] = PropertyContainer.SCENE.instantiate().init(root_container)
			containers_tree[container_name].container_name = container_name


func _on_field_value_changed(property_name: String, new_value: Variant):
	var blueprint := element_selected.blueprint
	if blueprint:
		blueprint.set_property(property_name, new_value)
		if property_name == "color":
			Game.ui.tab_blueprints.set_item_color(blueprint.id, new_value)
		if not unsaved_blueprints.has(blueprint):
			unsaved_blueprints.append(blueprint)
			save_blueprints()
	else:
		element_selected.set_property_value(property_name, new_value)
		var level := element_selected.level
		var map := level.map
		var id := element_selected.id
		var new_raw_value: Variant = element_selected.properties[property_name].get_raw()
		Game.server.rpcs.change_element_property.rpc(map.slug, level.index, id, property_name, new_raw_value)
	
	if property_name == "label" and Game.player:
		Game.ui.selected_map.selected_level.set_control(Game.player.elements)
			
	# custom params, update sliders
	if element_selected is Entity and property_name == "body_texture":
		refresh()
	if element_selected is Prop and property_name == "texture":
		refresh()


func save_blueprints():
	await get_tree().create_timer(2).timeout  # accumulate changes
	
	for blueprint in unsaved_blueprints:
		Game.campaign.set_blueprint_data(blueprint.path, blueprint.json())
		
	unsaved_blueprints.clear()


func _on_blueprint_changed(_property_name: String, blueprint: CampaignBlueprint):
	element_selected.set_property_value("blueprint", blueprint)
	if not blueprint:
		return
	
	element_selected.set_property_values(blueprint.properties)
	var level := element_selected.level
	var map := level.map
	var id := element_selected.id
	Game.server.rpcs.change_element_properties.rpc(map.slug, level.index, id,
			element_selected.get_raw_property_values())
	
	refresh()
	

func _on_blueprint_saved():
	var blueprint_properties := element_selected.get_raw_property_values()
	blueprint_properties.erase("blueprint")
	var blueprint := Game.ui.tab_blueprints.save_new(element_selected.type, element_selected.label, blueprint_properties)
	element_selected.set_property_value("blueprint", blueprint)
	
	refresh()


func refresh():
	_set_element_selected(element_selected)


func reset():
	_set_element_selected(null)
