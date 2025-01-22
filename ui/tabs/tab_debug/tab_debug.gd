class_name TabDebug
extends Control


@onready var output_text: RichTextLabel = %OutputText
@onready var clear_button: Button = %ClearButton
@onready var wrap_button: Button = %WrapButton
@onready var auto_button: Button = %AutoButton
@onready var debug_button: Button = %DebugButton
@onready var info_button: Button = %InfoButton
@onready var warning_button: Button = %WarningButton
@onready var error_button: Button = %ErrorButton
@onready var level_group: ButtonGroup = error_button.button_group
@onready var filter_line_edit: LineEdit = %FilterLineEdit


func _ready() -> void:
	Debug.send_message.connect(_on_send_message)
	
	clear_button.pressed.connect(_on_clear_button_pressed)
	wrap_button.button_pressed = true
	wrap_button.pressed.connect(_on_wrap_button_pressed)
	auto_button.button_pressed = true
	auto_button.pressed.connect(_on_auto_button_pressed)
	
	level_group.pressed.connect(_on_level_group_pressed)
	match Debug.level:
		Debug.DEBUG:
			debug_button.button_pressed = true
		Debug.INFO:
			info_button.button_pressed = true
		Debug.WARNING:
			warning_button.button_pressed = true
		Debug.ERROR:
			error_button.button_pressed = true
	
	output_text.scroll_following = true
	filter_line_edit.text = ""


func _on_send_message(text: String):
	var text_filtered := filter_line_edit.text
	if not text_filtered or text_filtered in text:
		output_text.append_text(text + "\n")
	

func _on_clear_button_pressed():
	output_text.clear()


func _on_wrap_button_pressed():
	if wrap_button.button_pressed:
		output_text.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	else:
		output_text.autowrap_mode = TextServer.AUTOWRAP_OFF


func _on_auto_button_pressed():
	output_text.scroll_following = auto_button.button_pressed


func _on_level_group_pressed(button: BaseButton):
	match button:
		debug_button:
			Debug.level = Debug.DEBUG
		info_button:
			Debug.level = Debug.INFO
		warning_button:
			Debug.level = Debug.WARNING
		error_button:
			Debug.level = Debug.ERROR
