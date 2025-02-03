class_name ColorField
extends PropertyField


const SCENE := preload("res://ui/tabs/tab_properties/field/color_field/color_field.tscn")
const POPUP_PANEL = preload("res://resources/themes/main/popup_panel.tres")


var property_value := Color.WHITE :
	set(value): color_picker_button.color = value
	get: return color_picker_button.color


@onready var color_picker_button: ColorPickerButton = %ColorPickerButton


func set_param(_param_name: String, _param_value: Variant):
	pass


func set_value(_value: Variant):
	property_value = _value


var picker: ColorPicker 
var popup: Popup 


func _ready() -> void:
	color_picker_button.color_changed.connect(_on_color_value_changed)
	
	picker = color_picker_button.get_picker()
	picker.color_modes_visible = false
	picker.can_add_swatches = false
	picker.presets_visible = false
	
	popup = color_picker_button.get_popup()
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
	popup.get_child(0).add_child(close_button)
	
	
func _on_color_value_changed(new_value: Color):
	value_changed.emit(property_name, new_value)
