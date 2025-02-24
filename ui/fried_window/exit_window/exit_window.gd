class_name ExitWindow
extends FriedWindow


signal response(delete: bool)


var exit_type: String :
	set(value):
		exit_type = value
		title_label.text = "Exit %s" % exit_type

@onready var title_label: Label = $M/VBoxContainer/TitleBar/H/TitleLabel
@onready var exit_button: Button = %ExitButton
@onready var cancel_button: Button = %CancelButton


func _ready() -> void:
	super._ready()
	
	visibility_changed.connect(_on_visibility_changed)
	exit_button.pressed.connect(_on_delete_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	close_button.pressed.connect(_on_cancel_button_pressed)


func _on_visibility_changed() -> void:
	if visible:
		cancel_button.grab_focus()
		Game.ui.mouse_blocker.visible = true


func _on_cancel_button_pressed() -> void:
	_on_close_button_pressed()
	response.emit(false)


func _on_delete_button_pressed() -> void:
	_on_close_button_pressed()
	response.emit(true)
