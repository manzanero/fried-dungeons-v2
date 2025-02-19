class_name TabMessages
extends Control


var origin_label := "Anonymus"
var origin_color := Color.WHITE


@onready var helper: Control = %HelperContainer
@onready var dice_button: Button = %DiceButton
@onready var history_button: Button = %HistoryButton
@onready var level_group: ButtonGroup = dice_button.button_group

@onready var dice_panel: PanelDice = %Dice
@onready var history_panel: PanelHistory = %History

@onready var command_button: MenuButton = %CommandButton
@onready var master_as_origin_button: Button = %AsMasterButton
@onready var player_as_origin_button: Button = %AsPlayerButton
@onready var selection_as_origin_button: Button = %AsSelectionButton
@onready var output_text_label: RichTextLabel = %OutputText
@onready var message_edit: LineEdit = %MessageLineEdit
@onready var send_message_button: Button = %SendMessageButton


func _ready() -> void:
	helper.visible = false
	dice_button.pressed.connect(_on_panel_button_pressed.bind(dice_panel, dice_button))
	dice_button.button_pressed = false
	history_button.pressed.connect(_on_panel_button_pressed.bind(history_panel, history_button))
	history_button.button_pressed = false
	
	dice_panel.add_dice.connect(_on_add_dice)
	history_panel.command_pressed.connect(_on_history_message_pressed)
	
	command_button.pressed.connect(_on_command_button_pressed)
	var command_popup := command_button.get_popup()
	command_popup.get_window().transparent = true
	command_popup.id_pressed.connect(_on_command_id_pressed)
	message_edit.text_submitted.connect(_on_submit)
	send_message_button.pressed.connect(_on_send_message_button)
	
	await get_tree().process_frame
	Game.ui.dicer.roll_result.connect(_on_dicer_roll_result)
	

func set_profile():
	if Game.campaign and Game.campaign.is_master:
		master_as_origin_button.visible = true
		player_as_origin_button.visible = false
		master_as_origin_button.button_pressed = true
	else:
		master_as_origin_button.visible = false
		player_as_origin_button.visible = true
		player_as_origin_button.button_pressed = true


func _on_panel_button_pressed(panel: Control, button: Button):
	helper.visible = button.button_pressed
	dice_panel.visible = dice_panel == panel
	history_panel.visible = history_panel == panel


func _on_add_dice(number: int, faces: int) -> void:
	if not _get_origin():
		return
		
	var dice_string := "%sd%s" % [number, faces] if faces else str(number)
	var text := "/roll " + dice_string
	history_panel.add_command(text)
	
	Game.ui.dicer.create_dice_roll.rpc(origin_label, origin_color, dice_string, randi_range(0, 999999))


func _on_dicer_roll_result(_origin_label: String, _origin_color: Color, dice_string: String, result: Array):
	var text := "/roll " + dice_string
	
	var result_int := 0
	for r in result:
		result_int += r
	var result_str = "[b]%s[/b] [color=dark_gray]%s[/color]" % [result_int, result]
	
	new_message.rpc(_origin_label, _origin_color, text)
	new_message.rpc(_origin_label, _origin_color, "Dice result:\n[center]%s[/center]" % result_str)
	

func _on_history_message_pressed(text: String) -> void:
	if message_edit.text == text:
		if process_message(text):
			return
		message_edit.clear()
		return
	
	message_edit.clear()
	message_edit.insert_text_at_caret(text)
	message_edit.grab_focus()
	
	
func _on_command_button_pressed() -> void:
	command_button.get_popup().position.y -= command_button.get_popup().size.y


func _on_command_id_pressed(id: int) -> void:
	message_edit.clear()
	match id:
		0: message_edit.text = "/roll "
		1: message_edit.text = "/echo "
	message_edit.grab_focus()
	message_edit.caret_column = len(message_edit.text)

func _on_submit(new_text: String) -> void:
	if not new_text:
		#dice_panel.add_dice.emit(1, 20)
		Utils.temp_error_tooltip("Write a message", 2, true)
		return
	
	if process_message(new_text):
		return
		
	message_edit.clear()


func _on_send_message_button() -> void:
	_on_submit(message_edit.text)
	

func _get_origin() -> bool:
	
	# As master
	origin_label = Game.master.username
	origin_color = Game.master.color
	
	# As player
	if player_as_origin_button.button_pressed:
		if not Game.player:
			Utils.temp_error_tooltip("Select a Player", 2, true)
			return false
			
		origin_label = Game.player.username
		origin_color = Game.player.color
	
	# As selection
	elif selection_as_origin_button.button_pressed:
		var origin = Game.ui.selected_map.selected_level.element_selected
		if not origin:
			Utils.temp_error_tooltip("Select an Element", 2, true)
			return false
			
		origin_label = origin.label
		origin_color = origin.color

	return true


func process_message(text: String) -> Error:
	if not _get_origin():
		return ERR_UNCONFIGURED
		
	history_panel.add_command(text)
	new_message.rpc(origin_label, origin_color, text)

	if text.begins_with('/roll ') and text != '/roll ':
		var dice_string = text.split('/roll ', false, 1)[0]
		var output_text = "Dice result:\n[center]%s[/center]" % [roll_command(dice_string)]
		new_message.rpc(origin_label, origin_color, output_text)
	
	return OK


func roll_command(dice_string: String) -> String:
	Game.ui.dicer.audio_stream_player.play()
	
	var parsed_dice := dice_syntax.dice_parser(dice_string)
	var result_data := dice_syntax.roll_parsed(parsed_dice)
	
	if result_data.error:
		return result_data.msg[0]
	
	var result_str = "[b]%s[/b]" % result_data.result
	for roll in result_data.rolls:
		result_str += " [color=dark_gray]%s[/color]" % str(roll.dice)
	return result_str


@rpc("call_local", "any_peer", "reliable")
func new_message(label: String, color: Color, text: String):
	var label_rich := label
	if color.get_luminance() < 0.33:
		label_rich = "[outline_color=white][outline_size=8]%s[/outline_size][/outline_color]" % label
	output_text_label.append_text("[b][color=%s]%s[/color]  ·  [/b]%s\n" % [color.to_html(), label_rich, text])
	output_text_label.append_text("[center][b][color=dark_gray]·[/color][/b][/center]\n")
	
	Debug.print_info_message("New message from \"%s\" (%s)" % [label, color.to_html()])
	

func reset():
	output_text_label.clear()
	set_profile()
