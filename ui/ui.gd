class_name UI
extends Control

signal save_campaign_button_pressed
signal reload_campaign_pressed


# nav bar
@onready var nav_campaing: PopupMenu = %Campaing
@onready var nav_preferences: PopupMenu = %Preferences
@onready var nav_help: PopupMenu = %Help

@onready var ide: MarginContainer = %IDE
@onready var main_menu: MainMenu = %MainMenu

# left section
@onready var tab_world: TabWorld = %World

# right section
@onready var tab_properties: TabProperties = %Properties
@onready var tab_settings: TabSettings = %Settings
@onready var tab_messages: TabMessages = %Messages

# center section
@onready var map_tabs: TabContainer = %TabMaps
@onready var tab_builder: TabBuilder = %Builder
@onready var build_border: Panel = %BuildBorder
@onready var dicer: Dicer = %Dicer
@onready var state_label_value: Label = %StateLabelValue
@onready var down: Control = %Down
@onready var minimize_down_button: Button = %MinimizeDownButton
@onready var restore_down_button: Button = %RestoreDownButton


var opened_maps: Array[Map] :
	get:
		var maps: Array[Map] = []
		for i in map_tabs.get_tab_count():
			maps.append(map_tabs.get_tab_control(i).map)
		return maps


var opened_map_slugs: Array[String] :
	get:
		var slugs: Array[String] = []
		for i in map_tabs.get_tab_count():
			slugs.append(map_tabs.get_tab_control(i).map.slug)
		return slugs
		
		
var selected_map_tab: TabMap :
	get:
		return map_tabs.get_current_tab_control()
		
var selected_map: Map :
	get:
		return selected_map_tab.map if selected_map_tab else null
		
var is_mouse_over_map_tab: bool :
	get:
		return selected_map_tab.is_mouse_over and not main_menu.visible

func _ready() -> void:
	nav_campaing.id_pressed.connect(_on_nav_campaing_id_pressed)
	nav_campaing.set_item_shortcut(0, Utils.action_shortcut("save"))
	
	tab_settings.info_changed.connect(_on_info_changed)
	tab_settings.ambient_changed.connect(_on_ambient_changed)
	
	minimize_down_button.pressed.connect(_on_minimize_down_pressed.bind(true))
	restore_down_button.pressed.connect(_on_minimize_down_pressed.bind(false))

	build_border.visible = false


func _on_nav_campaing_id_pressed(id: int):
	match id:
		4: save_campaign()
		2: change_campaign()
		1: reload_campaign()
		9: quit()


func save_campaign():
	save_campaign_button_pressed.emit()


func change_campaign():
	main_menu.visible = true


func reload_campaign():
	reload_campaign_pressed.emit()


func quit():
	get_tree().quit()


func _on_info_changed(label: String):
	selected_map_tab.name = label
	selected_map.label = label


func _on_ambient_changed(master_view: bool, light: float, color: Color):
	var map := selected_map
	map.is_master_view = master_view
	map.current_ambient_light = light
	map.current_ambient_color = color
	if master_view:
		map.master_ambient_light = light
		map.master_ambient_color = color
	else:
		map.ambient_light = light
		map.ambient_color = color


func _on_minimize_down_pressed(minimize: bool):
	minimize_down_button.visible = not minimize
	restore_down_button.visible = minimize
	down.visible = not minimize
	
