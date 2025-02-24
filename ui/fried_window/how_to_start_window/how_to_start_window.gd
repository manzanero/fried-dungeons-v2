class_name HowToStartWindow
extends FriedWindow

@onready var start_button: Button = %StartButton
@onready var set_up_button: Button = %SetUpButton
@onready var start_rich_text_label: RichTextLabel = %StartRichTextLabel
@onready var set_up_rich_text_label: RichTextLabel = %SetUpRichTextLabel

func reset():
	set_up_button.button_pressed = false
	set_up_rich_text_label.visible = false

func _ready() -> void:
	super()
	start_button.button_pressed = true
	set_up_button.button_pressed = false
	visibility_changed.connect(_on_visibility_changed)
	
	reset()
	start_rich_text_label.visible = true
	
	start_button.pressed.connect(func (): 
		reset()
		start_rich_text_label.visible = true
	)
	set_up_button.pressed.connect(func (): 
		reset()
		set_up_rich_text_label.visible = true
	)


func _on_visibility_changed() -> void:
	if visible:
		Game.ui.mouse_blocker.visible = true
