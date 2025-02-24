class_name ModeController
extends MarginContainer


signal mode_changed


enum Mode {
	NONE,
	# ground
	GROUND_PAINT_TILE, GROUND_PAINT_RECT, GROUND_PAINT_BUCKET, GROUND_ERASE_RECT,
	# wall
	WALL_BOUND, WALL_FENCE, WALL_BARRIER, WALL_BOX, WALL_PASSAGE,
	# edit
	EDIT_SELECT_WALL, EDIT_FLIP_WALL, EDIT_CHANGE_WALL, EDIT_PAINT_WALL, EDIT_CUT_WALL,
	# light
	LIGHT_OMNILIGHT,
	# entity
	ENTITY_3D_SHAPE, ENTITY_BILLBOARD,
	# prop
	PROP_3D_SHAPE, PROP_DECAL,
}

const GROUND_MODES: Array[Mode] = [Mode.GROUND_PAINT_TILE, Mode.GROUND_PAINT_RECT, Mode.GROUND_PAINT_BUCKET, Mode.GROUND_ERASE_RECT]
const WALL_MODES: Array[Mode] = [Mode.WALL_BOUND, Mode.WALL_FENCE, Mode.WALL_BARRIER, Mode.WALL_BOX, Mode.WALL_PASSAGE]
const EDIT_MODES: Array[Mode] = [Mode.EDIT_SELECT_WALL, Mode.EDIT_FLIP_WALL, Mode.EDIT_CHANGE_WALL, Mode.EDIT_PAINT_WALL, Mode.EDIT_CUT_WALL]
const LIGHT_MODES: Array[Mode] = [Mode.LIGHT_OMNILIGHT]
const ENTITY_MODES: Array[Mode] = [Mode.ENTITY_3D_SHAPE, Mode.ENTITY_BILLBOARD]
const PROP_MODES: Array[Mode] = [Mode.PROP_3D_SHAPE, Mode.PROP_DECAL]
const AREA_MODES: Array[Mode] = []
const MODES := [GROUND_MODES, WALL_MODES, EDIT_MODES, LIGHT_MODES, ENTITY_MODES, PROP_MODES, AREA_MODES]


var mode: Mode

var mode_str: String :
	get: return mode_to_str(mode)
	
func mode_to_str(_mode: Mode) -> String:
	return str(Mode.keys()[_mode]).capitalize()


@onready var modes: Control = %Modes
@onready var modes_button_group := Utils.create_button_group(modes.get_children(), true)

@onready var modes_options: Control = %ModesOptions

@onready var ground_options_button: Button = %GroundButton
@onready var ground_options: Control = %GroundOptions
@onready var ground_button_group := Utils.create_button_group(ground_options.get_children())
@onready var wall_options_button: Button = %WallButton
@onready var wall_options: Control = %WallOptions
@onready var wall_button_group := Utils.create_button_group(wall_options.get_children())
@onready var edit_options_button: Button = %WallEditButton
@onready var edit_options: Control = %WallEditOptions
@onready var edit_button_group := Utils.create_button_group(edit_options.get_children())
@onready var light_options_button: Button = %LightButton
@onready var light_options: Control = %LightOptions
@onready var light_button_group := Utils.create_button_group(light_options.get_children())
@onready var entity_options_button: Button = %EntityButton
@onready var entity_options: Control = %EntityOptions
@onready var entity_button_group := Utils.create_button_group(entity_options.get_children())
@onready var prop_options_button: Button = %PropButton
@onready var prop_options: Control = %PropOptions
@onready var prop_button_group := Utils.create_button_group(prop_options.get_children())
@onready var area_options_button: Button = %AreaButton
@onready var area_options: Control = %AreaOptions
@onready var area_button_group := Utils.create_button_group(area_options.get_children())

@onready var mode_hint: Control = %ModeHint
@onready var mode_label: Label = %ModeLabel

@onready var nodes = [
	[ground_options_button, ground_options, ground_button_group, GROUND_MODES],
	[wall_options_button, wall_options, wall_button_group, WALL_MODES],
	[edit_options_button, edit_options, edit_button_group, EDIT_MODES],
	[light_options_button, light_options, light_button_group, LIGHT_MODES],
	[entity_options_button, entity_options, entity_button_group, ENTITY_MODES],
	[prop_options_button, prop_options, prop_button_group, PROP_MODES],
	[area_options_button, area_options, area_button_group, AREA_MODES],
]


var tween: Tween


func reset():
	_reset_mode()
	Utils.reset_button_group(modes_button_group, true)
	

func _reset_mode():
	for options in modes_options.get_child(0).get_children():
		options.visible = false


func _ready() -> void:
	modes_options.visible = false
	mode_hint.modulate = Color.TRANSPARENT
	_reset_mode()
	
	# Modes
	var mode_keys := ["R", "T", "Y", "U", "I", "O", "P"]
	for i in modes.get_child_count():
		var mode_button: Button = modes.get_child(i)
		mode_button.pressed.connect(_on_options_button_pressed.bind(i))
		mode_button.tooltip_text = "(%s) %s" % [mode_keys[i], mode_button.tooltip_text]
		
	_set_options(0, ground_options)
	_set_options(1, wall_options)
	_set_options(2, edit_options)
	_set_options(3, light_options)
	_set_options(4, entity_options)
	_set_options(5, prop_options)
	
	
# mode options
var mode_option_keys := ["F", "G", "H", "J", "K", "L"]

func _set_options(mode_index: int, mode_options: Control):
	for i in mode_options.get_child_count():
		var mode_option_button: Button = mode_options.get_child(i)
		mode_option_button.pressed.connect(_on_mode_button_pressed.bind(i))
		mode_option_button.tooltip_text = "(%s) %s" % [mode_option_keys[i], mode_to_str(MODES[mode_index][i])]


func change_mode(new_mode: Mode):
	_reset_mode()
	
	mode = new_mode
	if mode == Mode.NONE:
		Utils.reset_button_group(modes_button_group)
		modes_options.visible = false
		show_mode()
		mode_changed.emit()
		return
	
	modes_options.visible = true
	for i in range(nodes.size()):
		var _modes: Array[Mode] = nodes[i][3]
		if new_mode not in _modes:
			continue
		
		nodes[i][0].button_pressed = true
		nodes[i][1].visible = true
		nodes[i][2].get_buttons()[_modes.find(new_mode)].button_pressed = true
		break
	
	show_mode()
	mode_changed.emit()


func _on_options_button_pressed(modes_index: int, mode_button_index: int = 0, with_key := false):
	var _options_button: Button = nodes[modes_index][0]
	var _modes: Array[Mode] = nodes[modes_index][3]
	
	# simulate click
	if with_key:
		_options_button.button_pressed = not _options_button.button_pressed
	
	if _options_button.button_pressed:
		change_mode(_modes[mode_button_index])
	else:
		change_mode(Mode.NONE)
	

func _on_mode_button_pressed(mode_button_index: int):
	match modes_button_group.get_pressed_button():
		ground_options_button:
			if ground_options.get_child_count() > mode_button_index:
				ground_options.get_child(mode_button_index).button_pressed = true
				mode = GROUND_MODES[mode_button_index]
		wall_options_button:
			if wall_options.get_child_count() > mode_button_index:
				wall_options.get_child(mode_button_index).button_pressed = true
				mode = WALL_MODES[mode_button_index]
		edit_options_button:
			if edit_options.get_child_count() > mode_button_index:
				edit_options.get_child(mode_button_index).button_pressed = true
				mode = EDIT_MODES[mode_button_index]
		entity_options_button:
			if entity_options.get_child_count() > mode_button_index:
				entity_options.get_child(mode_button_index).button_pressed = true
				mode = ENTITY_MODES[mode_button_index]
		light_options_button:
			if light_options.get_child_count() > mode_button_index:
				light_options.get_child(mode_button_index).button_pressed = true
				mode = LIGHT_MODES[mode_button_index]
		prop_options_button:
			if prop_options.get_child_count() > mode_button_index:
				prop_options.get_child(mode_button_index).button_pressed = true
				mode = PROP_MODES[mode_button_index]
		area_options_button:
			if area_options.get_child_count() > mode_button_index:
				area_options.get_child(mode_button_index).button_pressed = true
				mode = AREA_MODES[mode_button_index]
		_:
			return
	
	show_mode()
	
	mode_changed.emit()


func show_mode():
	if tween:
		mode_label.text = ""
		mode_hint.modulate = Color.TRANSPARENT
		tween.kill()
		
	if mode == Mode.NONE:
		mode_label.text = ""
		mode_hint.modulate = Color.TRANSPARENT
		tween.kill()
		return
		
	mode_label.text = mode_str
	mode_hint.modulate = Color.WHITE
	tween = get_tree().create_tween()
	tween.tween_property(mode_hint, "modulate", Color.WHITE, 1.0)
	tween.tween_property(mode_hint, "modulate", Color.TRANSPARENT, 1.0)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	

var _last_input: Key

func _unhandled_input(event: InputEvent) -> void:
	if not Game.campaign or not Game.campaign.is_master:
		return

	if event is InputEventKey:
		if event.is_released():
			_last_input = KEY_0
			return
			
		if not event.is_pressed():
			return
			
		if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_SHIFT):
			return
			
		# last good input
		var input: Key = event.keycode
		if _last_input == input:
			return
		_last_input = input
		
		match event.keycode:
			KEY_R: _on_options_button_pressed(0, 0, true)
			KEY_T: _on_options_button_pressed(1, 0, true)
			KEY_Y: _on_options_button_pressed(2, 0, true)
			KEY_U: _on_options_button_pressed(3, 0, true)
			KEY_I: _on_options_button_pressed(4, 0, true)
			KEY_O: _on_options_button_pressed(5, 0, true)
			#KEY_P: _on_options_button_pressed(6, 0, true)  # Area
			
			KEY_F: _on_mode_button_pressed(0)
			KEY_G: _on_mode_button_pressed(1)
			KEY_H: _on_mode_button_pressed(2)
			KEY_J: _on_mode_button_pressed(3)
			KEY_K: _on_mode_button_pressed(4)
