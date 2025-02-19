class_name ColorEdit
extends Button


signal color_changed(color: Color)


const POPUP_PANEL = preload("res://resources/themes/main/popup_panel.tres")
const FRIED_CONVEX_PANEL = preload("res://ui/fried_convex_panel/fried_convex_panel.tscn")


var picker: ColorPicker 
var popup: Popup
var is_open := false


var color := Color.WHITE :
	set(value): color_picker_button.color = value
	get: return color_picker_button.color


var button: ColorPickerButton :
	get: return color_picker_button


@onready var color_picker_button: ColorPickerButton = %ColorPickerButton


func _ready() -> void:
	color_picker_button.color_changed.connect(color_changed.emit)
	color_picker_button.pressed.connect(_on_button_pressed)
	
	picker = color_picker_button.get_picker()
	picker.color_modes_visible = false
	picker.can_add_swatches = false
	picker.presets_visible = false
	
	popup = color_picker_button.get_popup()
	popup.popup_hide.connect(func (): 
		is_open = false
	)
	popup.get_window().transparent = true
	popup.add_theme_stylebox_override("panel", POPUP_PANEL)
	popup.window_input.connect(func (event: InputEvent):
		if event is InputEventMouseButton:
			if not event.pressed:
				if event.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
					popup.hide()
	)
	
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(popup.hide)
	var panel := FRIED_CONVEX_PANEL.instantiate()
	panel.add_child(close_button)
	popup.get_child(0).add_child(panel)


func _on_button_pressed():
	is_open = true
