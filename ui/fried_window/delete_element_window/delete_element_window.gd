class_name DeleteElementWindow
extends FriedWindow


signal response(delete: bool)


var element_selected: Element :
	set(value):
		element_selected = value
		rich_text_label.text = element_selected.label


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


func _on_cancel_button_pressed() -> void:
	_on_close_button_pressed()
	response.emit(false)


func _on_delete_button_pressed() -> void:
	_on_close_button_pressed()
	response.emit(true)
