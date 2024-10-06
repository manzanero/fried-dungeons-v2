class_name TabMessages
extends Control


#signal command_roll(origin: Element, dice_string: String)
signal command_echo(origin: Element, text_string: String)


@onready var helper: Control = %HelperContainer
@onready var dice_button: Button = %DiceButton
@onready var history_button: Button = %HistoryButton
@onready var level_group: ButtonGroup = dice_button.button_group

@onready var dice_panel: PanelDice = %Dice
@onready var history_panel: PanelHistory = %History

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
	
	message_edit.text_submitted.connect(_on_submit)
	send_message_button.pressed.connect(_on_send_message_button)
	
	await get_tree().process_frame
	Game.ui.dicer.roll_result.connect(_on_dicer_roll_result)


func _on_panel_button_pressed(panel: Control, button: Button):
	helper.visible = button.button_pressed
	dice_panel.visible = dice_panel == panel
	history_panel.visible = history_panel == panel


func _on_add_dice(number: int, faces: int) -> void:
	var dice_string := "%sd%s" % [number, faces]
	var text := "/roll " + dice_string
	history_panel.add_command(text)
	
	var map = Game.ui.selected_map
	var origin: Element = null
	if map and selection_as_origin_button.button_pressed:
		origin = map.selected_level.element_selected

	var origin_label := Game.master.username
	if origin:
		origin_label = origin.label 
	elif Game.player:
		origin_label = Game.player.username
		
	var origin_color := Game.master.color
	if origin:
		origin_color = origin.color
	elif Game.player:
		origin_color = Game.player.color
	
	Game.ui.dicer.create_dice_roll.rpc(origin_label, origin_color, dice_string, randi_range(0, 999999))


func _on_dicer_roll_result(origin_label: String, origin_color: Color, dice_string: String, result: Array):
	var text := "/roll " + dice_string
	
	var result_int := 0
	for r in result:
		result_int += r
	var result_str = "[b]%s[/b] [color=dark_gray]%s[/color]" % [result_int, result]
	
	new_message.rpc(origin_label, origin_color, text)
	new_message.rpc(origin_label, origin_color, "Dice result:\n[center]%s[/center]" % result_str)
	

func _on_history_message_pressed(text: String) -> void:
	if message_edit.text == text:
		process_message(text)
		message_edit.clear()
		return
	
	message_edit.clear()
	message_edit.insert_text_at_caret(text)
	message_edit.grab_focus()


func _on_submit(new_text: String) -> void:
	if not new_text:
		return
	
	message_edit.clear()
	process_message(new_text)


func _on_send_message_button() -> void:
	_on_submit(message_edit.text)


func process_message(text: String):
	history_panel.add_command(text)
	
	var map = Game.ui.selected_map
	var origin: Element = null
	if map and selection_as_origin_button.button_pressed:
		origin = map.selected_level.element_selected

	var origin_label := Game.master.username
	if origin:
		origin_label = origin.label 
	elif Game.player:
		origin_label = Game.player.username
		
	var origin_color := Game.master.color
	if origin:
		origin_color = origin.color
	elif Game.player:
		origin_color = Game.player.color
		
	new_message.rpc(origin_label, origin_color, text)

	if text.begins_with('/roll '):
		var dice_string = text.split('/roll ', false, 1)[0]
		var output_text = "Dice result:\n[center]%s[/center]" % [roll_command(dice_string)]
		new_message.rpc(origin_label, origin_color, output_text)
			
	else:
		command_echo.emit(origin, text)


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
	if color.get_luminance() < 0.5:
		label_rich = "[outline_color=white][outline_size=8]%s[/outline_size][/outline_color]" % label
	output_text_label.append_text("[b][color=%s]%s[/color]  ·  [/b]%s\n" % [color.to_html(), label_rich, text])
	output_text_label.append_text("[center][b][color=dark_gray]·[/color][/b][/center]\n")
	
	Debug.print_info_message("New message from \"%s\" (%s)" % [label, color.to_html()])
