@tool
class_name NumberEdit
extends Control


signal changed()
signal value_changed(value: float)

const DEFAULT_VALUE := 0.0

@export var prefix := "" :
	set(value): 
		prefix = value; if not is_node_ready(): await ready
		prefix_container.visible = value != ""
		prefix_label.text = prefix
@export var suffix := "" :
	set(value): 
		suffix = value; if not is_node_ready(): await ready
		suffix_container.visible = value != ""
		suffix_label.text = suffix
@export var has_slider := false :
	set(value): 
		has_slider = value; if not is_node_ready(): await ready
		slider_container.visible = value
@export var has_arrows := false :
	set(value): 
		has_arrows = value; if not is_node_ready(): await ready
		left_button.visible = value
		right_button.visible = value
		#arrows_container.visible = value

@export var rounded := false : 
	set(value): 
		rounded = value; if not is_node_ready(): await ready
		slider.rounded = rounded; if _emit_signal: changed.emit()
@export var min_value := 0.0 : 
	set(value): 
		min_value = value; if not is_node_ready(): await ready
		slider.min_value = min_value; if _emit_signal: changed.emit()
@export var max_value := 100.0 : 
	set(value): 
		max_value = value; if not is_node_ready(): await ready
		slider.max_value = max_value; if _emit_signal: changed.emit()
@export var step := 1.0 : 
	set(value): 
		step = value; if not is_node_ready(): await ready
		slider.step = step; if _emit_signal: changed.emit()
@export var allow_greater := false : 
	set(value): 
		allow_greater = value; if not is_node_ready(): await ready
		slider.allow_greater = allow_greater; if _emit_signal: changed.emit()
@export var allow_lesser := false : 
	set(value): 
		allow_lesser = value; if not is_node_ready(): await ready
		slider.allow_lesser = allow_lesser; if _emit_signal: changed.emit()


@export var text := "" : set = _set_text

var value := DEFAULT_VALUE : 
	set(_value): value = _value; if _emit_signal: value_changed.emit(value)


var _dragged := false
#var _last_valid_value := DEFAULT_VALUE
var _emit_signal := true


#func init_value(_value: float):
	#line_edit.text = str(_value)
	#slider.set_value_no_signal(_value)


func set_value_no_signal(_value: float):
	_emit_signal = false
	value = _value
	_emit_signal = true
	
	line_edit.text = str(_value)
	slider.set_value_no_signal(_value)
	


#region onready

@onready var prefix_container: MarginContainer = %PrefixContainer
@onready var prefix_label: Label = %PrefixLabel
@onready var suffix_container: MarginContainer = %SuffixContainer
@onready var suffix_label: Label = %SuffixLabel
@onready var line_edit: LineEdit = %LineEdit
@onready var slider_container: Container = %SliderContainer
@onready var slider: HSlider = %Slider
@onready var arrows_container: Container = %ArrowsContainer
@onready var left_button: Button = %LeftButton
@onready var right_button: Button = %RightButton


func _ready() -> void:
	line_edit.text_changed.connect(_set_text)
	slider.drag_started.connect(_on_slider_drag_started)
	slider.drag_ended.connect(_on_slider_drag_ended)
	left_button.pressed.connect(_on_left_button_pressed)
	right_button.pressed.connect(_on_right_button_pressed)


#endregion


func _set_text(_value: String) -> void:
	text = _value
	if not is_node_ready(): 
		await ready
		
	if _validate_text(_value):
		value = float(_value.to_int()) if rounded else _value.to_float()
		
		var caret_column := line_edit.caret_column
		line_edit.text = _value
		line_edit.caret_column = caret_column
		
		slider.set_value_no_signal(value)
		
		if _emit_signal: 
			value_changed.emit(value)

func _validate_text(new_text: String):
	if rounded and new_text.is_valid_int():
		return true
	elif new_text.is_valid_float():
		return true
	return false


func _on_left_button_pressed() -> void:
	value -= step
	line_edit.text = str(value)
	slider.set_value_no_signal(value)

func _on_right_button_pressed() -> void:
	value += step
	line_edit.text = str(value)
	slider.set_value_no_signal(value)


func _on_slider_drag_started() -> void:
	_dragged = true

func _on_slider_drag_ended(_value_changed: bool) -> void:
	_dragged = false


func _process(_delta: float) -> void:
	if _dragged:
		value = slider.value
		line_edit.text = str(value)
	
