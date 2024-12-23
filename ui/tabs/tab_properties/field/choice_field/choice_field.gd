class_name ChoiceField
extends PropertyField


static var SCENE := preload("res://ui/tabs/tab_properties/field/choice_field/choice_field.tscn")


var property_value : String :
	set(value): 
		for i in range(option_button.item_count):
			var option_text := option_button.get_item_text(i)
			if option_codes[option_text] == value:
				option_button.select(i)
				return
		Debug.print_warning_message("There is no item \"%s\" in \"%s\" options" % [value, property_name])
	get: return option_codes[option_button.get_item_text(option_button.selected)]

	
var option_codes := {}


@onready var option_button: OptionButton = %OptionButton


func set_param(_param_name: String, _param_value: Variant):
	match _param_name:
		"choices": 
			option_codes.clear()
			option_button.clear()
			for option in _param_value:
				option_button.add_item(option[1])
				option_codes[option[1]] = option[0]


func set_value(_value: Variant):
	property_value = _value


func get_value() -> String:
	return property_value


func _ready() -> void:
	option_button.get_popup().get_window().transparent = true
	option_button.item_selected.connect(_on_item_selected)
	
	for i in range(option_button.item_count):
		var option_label := option_button.get_item_text(i)
		option_codes[option_label] = option_label.to_lower().replace(" ", "_")

func _on_item_selected(_index: int):
	change_value(property_value)
