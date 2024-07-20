class_name UI
extends Control

@onready var tab_properties: TabProperties = %Properties
@onready var tab_settings: TabSettings = %Settings
@onready var tab_messages: TabMessages = %Messages

@onready var map_tabs: TabContainer = %TabMaps
@onready var dicer: Dicer = %Dicer

var selected_map_tab: TabMap :
	get:
		return map_tabs.get_current_tab_control()
var selected_map: Map :
	get:
		return selected_map_tab.map
var is_mouse_over_map_tab = true


func _ready() -> void:
	tab_settings.info_changed.connect(_on_info_changed)
	tab_settings.ambient_changed.connect(_on_ambient_changed)


func _on_info_changed(title: String):
	selected_map_tab.name = title
	selected_map.title = title


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

