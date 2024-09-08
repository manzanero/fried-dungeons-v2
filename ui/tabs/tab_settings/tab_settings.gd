class_name TabSettings
extends Control


signal info_changed(title: String)
signal ambient_changed(master_view: bool, light: float, color: Color)


var cached_valid_label: String


# info
@onready var info_container: PropertyContainer = %InfoContainer
@onready var title_field: StringField = %TitleField
@onready var title_edit: LineEdit = title_field.line_edit

# ambient
@onready var ambient_container: PropertyContainer = %AmbientContainer
@onready var ambient_light_field: FloatField = %AmbientLightField
@onready var ambient_light_spin: SpinBox = ambient_light_field.spin_box
@onready var ambient_color_field: ColorField = %AmbientColorField
@onready var ambient_color_button: ColorPickerButton = ambient_color_field.color_picker_button
@onready var master_view_field: BoolField = %MasterViewField
@onready var master_view_check: CheckBox = master_view_field.check_box
@onready var override_ambient_light_field: BoolField = %OverrideAmbientLightField
@onready var override_ambient_light_check: CheckBox = override_ambient_light_field.check_box
@onready var master_ambient_light_field: FloatField = %MasterAmbientLightField
@onready var master_ambient_light_spin: SpinBox = master_ambient_light_field.spin_box
@onready var override_ambient_color_field: BoolField = %OverrideAmbientColorField
@onready var override_ambient_color_check: CheckBox = override_ambient_color_field.check_box
@onready var master_ambient_color_field: ColorField = %MasterAmbientColorField
@onready var master_ambient_color_button: ColorPickerButton = master_ambient_color_field.color_picker_button



func _ready() -> void:
	
	# info
	info_container.collapsable = false
	info_container.collapsed = false
	title_edit.text_changed.connect(_on_info_edited.unbind(1))
	
	# ambient
	ambient_container.collapsable = true
	ambient_container.collapsed = false
	ambient_light_spin.value_changed.connect(_on_ambient_edited.unbind(1))
	ambient_color_button.color_changed.connect(_on_ambient_edited.unbind(1))
	master_view_check.pressed.connect(_on_ambient_edited)
	override_ambient_light_check.pressed.connect(_on_ambient_edited)
	master_ambient_light_spin.value_changed.connect(_on_ambient_edited.unbind(1))
	override_ambient_color_check.pressed.connect(_on_ambient_edited)
	master_ambient_color_button.color_changed.connect(_on_ambient_edited.unbind(1))


func _on_info_edited():
	var label := title_edit.text.validate_filename()
	if not label:
		label = "Untitled"
	
	var caret_column := title_edit.caret_column
	title_edit.text = label
	title_edit.caret_column = caret_column
	info_changed.emit(label)


func _on_ambient_edited():
	var master_view := master_view_check.button_pressed
	var light := ambient_light_spin.value / 100.0
	var color := ambient_color_button.color

	if master_view:
		if override_ambient_light_check.button_pressed:
			light = master_ambient_light_spin.value / 100.0
		if override_ambient_color_check.button_pressed:
			color = master_ambient_color_button.color
	
	ambient_changed.emit(master_view, light, color)
