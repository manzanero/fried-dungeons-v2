class_name TabBuilder
extends Control


var material_index_selected := 0


const ATLAS_TEXTURE_BUTTON = preload("res://ui/tabs/tab_builder/atlas_texture_button/atlas_texture_button.tscn")


@export var materials: Control

@onready var one_side_button: Button = %OneSideButton
@onready var two_side_button: Button = %TwoSideButton
@onready var room_button: Button = %RoomButton
@onready var obstable_button: Button = %ObstableButton

@onready var move_button: Button = %MoveButton
@onready var cut_button: Button = %CutButton
@onready var change_button: Button = %ChangeButton
@onready var flip_button: Button = %FlipButton
@onready var wall_button: Button = %WallButton

@onready var tile_button: Button = %TileButton
@onready var rect_button: Button = %RectButton

@onready var new_object_button: Button = %NewObjectButton
@onready var new_entity_button: Button = %NewEntityButton
@onready var new_light_button: Button = %NewLightButton


func _ready() -> void:
	for child in materials.get_children():
		child.queue_free()
		
	for i in range(64):
		var button: AtlasTextureButton = ATLAS_TEXTURE_BUTTON.instantiate().init(materials, i)
		button.pressed.connect(func (index): 
			material_index_selected = index
		)

	one_side_button.pressed.connect(_on_button_pressed.bind(one_side_button, ONE_SIDED))
	two_side_button.pressed.connect(_on_button_pressed.bind(two_side_button, TWO_SIDED))
	room_button.pressed.connect(_on_button_pressed.bind(room_button, ROOM))
	obstable_button.pressed.connect(_on_button_pressed.bind(obstable_button, OBSTACLE))
	
	move_button.pressed.connect(_on_button_pressed.bind(move_button, MOVE))
	cut_button.pressed.connect(_on_button_pressed.bind(cut_button, CUT))
	change_button.pressed.connect(_on_button_pressed.bind(change_button, CHANGE))
	flip_button.pressed.connect(_on_button_pressed.bind(flip_button, FLIP))
	wall_button.pressed.connect(_on_button_pressed.bind(wall_button, PAINT_WALL))
	
	tile_button.pressed.connect(_on_button_pressed.bind(tile_button, PAINT_TILE))
	rect_button.pressed.connect(_on_button_pressed.bind(rect_button, PAINT_RECT))
	
	new_object_button.pressed.connect(_on_button_pressed.bind(new_object_button, NEW_OBJECT))
	new_entity_button.pressed.connect(_on_button_pressed.bind(new_entity_button, NEW_ENTITY))
	new_light_button.pressed.connect(_on_button_pressed.bind(new_light_button, NEW_LIGHT))

	visibility_changed.connect(_on_visibility_changed)


func _on_button_pressed(button: Button, mode: int) -> void:
	var state_machine := Game.ui.selected_map.selected_level.state_machine
	if button.button_pressed:
		state_machine.get_state_node("Building").mode = mode
		state_machine.change_state("Building")
	else:
		state_machine.change_state("Idle")


func _on_visibility_changed():
	var state_machine := Game.ui.selected_map.selected_level.state_machine
	if not visible:
		if state_machine.state == "Building":
			state_machine.change_state("Idle")
		var button := tile_button.button_group.get_pressed_button()
		if button:
			button.button_pressed = false



#func _set_wall_selected(wall: Wall):
	#Utils.safe_queue_free(properties_container)
	#containers_tree.clear()
	#if not element:
		#if is_instance_valid(element_selected):
			#Debug.print_message(Debug.DEBUG, "Element \"%s\" unselected" % element_selected.name)
		#return
		#
	#element_selected = element
	#Debug.print_message(Debug.INFO, "Element \"%s\" selected" % element_selected.name) 
	#
	#root_container = PROPERTY_CONTAINER.instantiate().init(property_containers)
	#root_container.container_name = element_selected.name
	#root_container.collapsable = false
	#
	#var properties := element_selected.properties
	#_make_containers_tree(properties)
	#
	#for property_name in properties:
		#var property: Element.Property = properties[property_name]
		#var property_container: PropertyContainer = containers_tree[property.container]
		#var field: PropertyField
		#match property.hint:
			#Element.Property.Hints.STRING:
				#field = STRING_FIELD.instantiate().init(property_container, property_name, property.value)
			#Element.Property.Hints.COLOR:
				#field = COLOR_FIELD.instantiate().init(property_container, property_name, property.value)
			#Element.Property.Hints.BOOL:
				#field = BOOL_FIELD.instantiate().init(property_container, property_name, property.value)
			#Element.Property.Hints.FLOAT:
				#field = FLOAT_FIELD.instantiate().init(property_container, property_name, property.value)
			#_:
				#Debug.print_message(Debug.ERROR, "Unkown type \"%s\" of property \"%s\"" % [typeof(property.value), property_name]) 
		#field.value_changed.connect(_on_field_value_changed)


enum {
	PAINT_TILE, PAINT_RECT,
	MOVE, CUT, CHANGE, FLIP, PAINT_WALL,
	ONE_SIDED, TWO_SIDED, ROOM, OBSTACLE,
	NEW_OBJECT, NEW_ENTITY, NEW_LIGHT,
}
