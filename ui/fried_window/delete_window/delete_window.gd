class_name DeleteWindow
extends FriedWindow


signal response(delete: bool)


var item_type: String :
	set(value):
		item_type = value
		title_label.text = "Delete %s" % item_type
		
var item_selected: String :
	set(value):
		item_selected = value
		rich_text_label.text = item_selected

@onready var title_label: Label = $M/VBoxContainer/TitleBar/H/TitleLabel
@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var delete_button: Button = %DeleteButton
@onready var cancel_button: Button = %CancelButton


func _ready() -> void:
	super._ready()
	
	visibility_changed.connect(_on_visibility_changed)
	delete_button.pressed.connect(_on_delete_button_pressed)
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
