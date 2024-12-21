class_name NavBar
extends Control

const SCENE := preload("res://ui/nav_bar/nav_bar.tscn")

enum MenuItemType {
	SEPARATOR,
	BUTTON,
}


signal campaign_new_pressed
signal campaign_host_pressed
signal campaign_join_pressed

signal campaign_settings_pressed

signal campaign_save_pressed
signal campaign_reload_pressed

signal campaign_quit_pressed

const CAMPAIGN_MENU_ITEM_NEW := "New..."
const CAMPAIGN_MENU_ITEM_HOST := "Load..."
const CAMPAIGN_MENU_ITEM_JOIN := "Join..."

const CAMPAIGN_MENU_ITEM_SETTINGS := "Settings..."

const CAMPAIGN_MENU_ITEM_SAVE := "Save"
const CAMPAIGN_MENU_ITEM_RELOAD := "Reload"

const CAMPAIGN_MENU_ITEM_QUIT := "Quit"

var campaign_menu_items := [
	{"type": MenuItemType.BUTTON, "label": CAMPAIGN_MENU_ITEM_NEW, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_N},
	{"type": MenuItemType.BUTTON, "label": CAMPAIGN_MENU_ITEM_HOST, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_H},
	{"type": MenuItemType.BUTTON, "label": CAMPAIGN_MENU_ITEM_JOIN, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_J},
	{"type": MenuItemType.SEPARATOR},
	{"type": MenuItemType.BUTTON, "label": CAMPAIGN_MENU_ITEM_SETTINGS},
	{"type": MenuItemType.SEPARATOR},
	{"type": MenuItemType.BUTTON, "label": CAMPAIGN_MENU_ITEM_SAVE, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_S},
	{"type": MenuItemType.BUTTON, "label": CAMPAIGN_MENU_ITEM_RELOAD, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_R},
	{"type": MenuItemType.SEPARATOR},
	{"type": MenuItemType.BUTTON, "label": CAMPAIGN_MENU_ITEM_QUIT, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_Q},
]


@onready var campaign_menu: PopupMenu = %Campaing
@onready var preferences_menu: PopupMenu = %Preferences
@onready var help_menu: PopupMenu = %Help

@onready var flow_controller: FlowController = %FlowController
@onready var master_volume_controller: HBoxContainer = %MasterVolumeController


var _campaign_menu_ids := {}


func _ready() -> void:
	Game.flow = flow_controller
	
	var index := 0
	for item in campaign_menu_items:
		match item.type:
			MenuItemType.SEPARATOR:
				campaign_menu.add_separator(item.get("label", ""), index)
			MenuItemType.BUTTON:
				_campaign_menu_ids[item.label] = index
				campaign_menu.add_item(item.label, index, item.get("shortcut", 0))
		index += 1
	
	campaign_menu.id_pressed.connect(_on_campaing_menu_id_pressed)
	
	campaign_menu.get_window().transparent = true
	preferences_menu.get_window().transparent = true
	help_menu.get_window().transparent = true
	
	set_profile()


func set_profile() -> void:
	if Game.campaign:
		var is_master := Game.campaign.is_master
		set_campaing_menu_item_disabled(CAMPAIGN_MENU_ITEM_SETTINGS, not is_master)
		set_campaing_menu_item_disabled(CAMPAIGN_MENU_ITEM_SAVE, not is_master)
		set_campaing_menu_item_disabled(CAMPAIGN_MENU_ITEM_RELOAD, false)
		#master_volume_controller.visible = true
	else:
		set_campaing_menu_item_disabled(CAMPAIGN_MENU_ITEM_RELOAD, true)
		#master_volume_controller.visible = false
	
	flow_controller.set_profile()


func _on_campaing_menu_id_pressed(id: int):
	var item_label := campaign_menu.get_item_text(id)
	match item_label:
		CAMPAIGN_MENU_ITEM_NEW: campaign_new_pressed.emit()
		CAMPAIGN_MENU_ITEM_HOST: campaign_host_pressed.emit()
		CAMPAIGN_MENU_ITEM_JOIN: campaign_join_pressed.emit()
		CAMPAIGN_MENU_ITEM_SETTINGS: campaign_settings_pressed.emit()
		CAMPAIGN_MENU_ITEM_SAVE: campaign_save_pressed.emit()
		CAMPAIGN_MENU_ITEM_RELOAD: campaign_reload_pressed.emit()
		CAMPAIGN_MENU_ITEM_QUIT: campaign_quit_pressed.emit()


func _get_item_id(item_label: String) -> int:
	return _campaign_menu_ids[item_label]


func _get_item_index(item_label: String) -> int:
	var index := 0
	for items in campaign_menu_items:
		if items.get("label") == item_label:
			return index
		index += 1
	return -1


func set_campaing_menu_item_disabled(item_label: String, value: bool):
	var item_index := _get_item_index(item_label)
	campaign_menu.set_item_disabled(item_index, value)
