class_name TabSettings
extends Control


signal info_changed(title: String)
#signal ambient_changed(master_view: bool, light: float, color: Color, master_light: float, master_color: Color)


var cached_valid_label: String


# info
@onready var info_container: PropertyContainer = %InfoContainer
@onready var title_field: StringField = %TitleField
@onready var title_edit: LineEdit = title_field.line_edit

# ambient
@onready var ambient_container: PropertyContainer = %AmbientContainer
@onready var ambient_light_field: FloatField = %AmbientLightField
@onready var ambient_light_field_edit: NumberEdit = ambient_light_field.number_edit
@onready var ambient_color_field: ColorField = %AmbientColorField
@onready var ambient_color_button: ColorPickerButton = ambient_color_field.color_picker_button
@onready var master_view_field: BoolField = %MasterViewField
@onready var master_view_check: CheckBox = master_view_field.check_box
@onready var override_ambient_light_field: BoolField = %OverrideAmbientLightField
@onready var override_ambient_light_check: CheckBox = override_ambient_light_field.check_box
@onready var master_ambient_light_field: FloatField = %MasterAmbientLightField
@onready var master_ambient_light_field_edit: NumberEdit = master_ambient_light_field.number_edit
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
	ambient_light_field_edit.value_changed.connect(_on_ambient_edited.unbind(1))
	ambient_color_button.color_changed.connect(_on_ambient_edited.unbind(1))
	master_view_check.pressed.connect(_on_ambient_edited)
	override_ambient_light_check.pressed.connect(_on_ambient_edited)
	master_ambient_light_field_edit.value_changed.connect(_on_ambient_edited.unbind(1))
	override_ambient_color_check.pressed.connect(_on_ambient_edited)
	master_ambient_color_button.color_changed.connect(_on_ambient_edited.unbind(1))


func _on_info_edited():
	var label := title_edit.text.strip_edges()
	
	info_changed.emit(label if label else "Untitled")


func _on_ambient_edited():
	var map := Game.ui.selected_map
	map.ambient_light = ambient_light_field.property_value / 100.0
	map.ambient_color = ambient_color_button.color
	map.master_ambient_light = master_ambient_light_field.property_value / 100.0
	map.master_ambient_color = master_ambient_color_button.color
	map.override_ambient_light = override_ambient_light_check.button_pressed
	map.override_ambient_color = override_ambient_color_check.button_pressed
	map.current_ambient_light = map.ambient_light
	map.current_ambient_color = map.ambient_color
	
	Game.server.rpcs.change_ambient.rpc(map.slug, 
			map.ambient_light,
			map.ambient_color,
			map.master_ambient_light,
			map.master_ambient_color)
	
	map.is_master_view = master_view_check.button_pressed
	if not map.is_master_view:
		return
	
	if override_ambient_light_check.button_pressed:
		map.current_ambient_light = map.master_ambient_light
	if override_ambient_color_check.button_pressed:
		map.current_ambient_color = map.master_ambient_color


func reset():
	var map := Game.ui.selected_map
	if not map:
		return
	
	# info
	title_edit.text = Game.ui.selected_scene_tab.name
	
	# ambient
	ambient_light_field_edit.set_value_no_signal(map.ambient_light * 100.0)
	ambient_color_button.color = map.ambient_color
	master_ambient_light_field_edit.set_value_no_signal(map.master_ambient_light * 100.0)
	master_ambient_color_button.color = map.master_ambient_color
	override_ambient_light_check.set_pressed_no_signal(map.override_ambient_light)
	override_ambient_color_check.set_pressed_no_signal(map.override_ambient_color)
