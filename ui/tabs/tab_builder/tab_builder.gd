class_name TabBuilder
extends Control


var material_index_selected := 5


const ATLAS_TEXTURE_BUTTON = preload("res://ui/tabs/tab_builder/atlas_texture_button/atlas_texture_button.tscn")


@export var mode_button_group: ButtonGroup
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


func _ready() -> void:
	for child in materials.get_children():
		child.queue_free()
		
	for i in range(2, 64):
		var button: AtlasTextureButton = ATLAS_TEXTURE_BUTTON.instantiate().init(materials, i)
		button.pressed.connect(func (index): 
			material_index_selected = index
		)
		if material_index_selected == i:
			button.button_pressed = true
		
	one_side_button.pressed.connect(_on_button_pressed.bind(one_side_button, LevelBuildingState.ONE_SIDED))
	two_side_button.pressed.connect(_on_button_pressed.bind(two_side_button, LevelBuildingState.TWO_SIDED))
	room_button.pressed.connect(_on_button_pressed.bind(room_button, LevelBuildingState.ROOM))
	obstable_button.pressed.connect(_on_button_pressed.bind(obstable_button, LevelBuildingState.OBSTACLE))
	
	move_button.pressed.connect(_on_button_pressed.bind(move_button, LevelBuildingState.MOVE))
	cut_button.pressed.connect(_on_button_pressed.bind(cut_button, LevelBuildingState.CUT))
	change_button.pressed.connect(_on_button_pressed.bind(change_button, LevelBuildingState.CHANGE))
	flip_button.pressed.connect(_on_button_pressed.bind(flip_button, LevelBuildingState.FLIP))
	wall_button.pressed.connect(_on_button_pressed.bind(wall_button, LevelBuildingState.PAINT_WALL))
	
	tile_button.pressed.connect(_on_button_pressed.bind(tile_button, LevelBuildingState.PAINT_TILE))
	rect_button.pressed.connect(_on_button_pressed.bind(rect_button, LevelBuildingState.PAINT_RECT))

	visibility_changed.connect(_on_visibility_changed)


func _on_button_pressed(button: Button, mode: int) -> void:
	var state_machine := Game.ui.selected_map.selected_level.state_machine
	if button.button_pressed:
		state_machine.get_state_node("Building").mode = mode
		state_machine.change_state("Building")
	else:
		state_machine.change_state("Idle")


func _on_visibility_changed():
	if not Game.ui.selected_map:
		return
	
	var state_machine := Game.ui.selected_map.selected_level.state_machine
	if not visible:
		if state_machine.state == "Building":
			state_machine.change_state("Idle")
			Utils.reset_button_group(tile_button.button_group)
			

func reset():
	Game.ui.build_border.visible = false
	Utils.reset_button_group(mode_button_group)

	if Game.ui.selected_map and Game.ui.selected_map.selected_level:
		Game.ui.selected_map.selected_level.state_machine.change_state("Idle")
