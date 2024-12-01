class_name ChoiceField
extends PropertyField


var property_value : String :
	set(value): 
		for i in range(option_button.item_count):
			var option_text := option_button.get_item_text(i)
			if option_text == value:
				option_button.select(i)
				return
		Debug.print_warning_message("There is no item \"%s\" in \"%s\" options" % [value, property_name])
	get: return option_button.get_item_text(option_button.selected)


@onready var option_button: OptionButton = %OptionButton


func set_param(_param_name: String, _param_value: Variant):
	pass


func set_value(_value: Variant):
	property_value = _value


func _ready() -> void:
	option_button.get_popup().get_window().transparent = true
	option_button.item_selected.connect(_on_item_selected)
	

func _on_item_selected(_index: int):
	change_value(property_value)
