class_name PanelDice
extends Control


signal add_dice(number: int, faces: int)
signal add_operator(operator_text: String)


@onready var dice_buttons: GridContainer = %DiceButtons
@onready var operator_buttons: GridContainer = $HBoxContainer/OperatorButtons


func _ready() -> void:
	for button: Button in dice_buttons.get_children():
		button.pressed.connect(_on_button_pressed.bind(button))
	for button: Button in operator_buttons.get_children():
		button.pressed.connect(_on_operator_button_pressed.bind(button))


func _on_button_pressed(button: Button):
	var data = button.name.lstrip("D").split("_")
	add_dice.emit(int(data[1]), int(data[0]))


func _on_operator_button_pressed(button: Button):
	add_operator.emit(button.text)
