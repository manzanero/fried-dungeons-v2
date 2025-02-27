class_name NavBar
extends Control


enum MenuItemType {
	SEPARATOR,
	BUTTON,
}


signal campaign_new_pressed
signal campaign_host_pressed
signal campaign_join_pressed

signal campaign_settings_pressed
signal campaign_players_pressed

signal campaign_save_pressed
signal campaign_reload_pressed

signal campaign_quit_pressed

const CAMPAIGN_MENU_ITEM_NEW := "New..."
const CAMPAIGN_MENU_ITEM_HOST := "Host..."
const CAMPAIGN_MENU_ITEM_JOIN := "Join..."

const CAMPAIGN_MENU_ITEM_SETTINGS := "Settings..."
const CAMPAIGN_MENU_ITEM_PLAYERS := "Players..."

const CAMPAIGN_MENU_ITEM_SAVE := "Save"
const CAMPAIGN_MENU_ITEM_RELOAD := "Reload"

const CAMPAIGN_MENU_ITEM_QUIT := "Quit"

var campaign_menu_items := [
	{"type": MenuItemType.BUTTON, "label": CAMPAIGN_MENU_ITEM_NEW, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_N},
	{"type": MenuItemType.BUTTON, "label": CAMPAIGN_MENU_ITEM_HOST, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_H},
	{"type": MenuItemType.BUTTON, "label": CAMPAIGN_MENU_ITEM_JOIN, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_J},
	{"type": MenuItemType.SEPARATOR},
	{"type": MenuItemType.BUTTON, "label": CAMPAIGN_MENU_ITEM_SETTINGS, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_T},
	{"type": MenuItemType.BUTTON, "label": CAMPAIGN_MENU_ITEM_PLAYERS, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_P},
	{"type": MenuItemType.SEPARATOR},
	{"type": MenuItemType.BUTTON, "label": CAMPAIGN_MENU_ITEM_SAVE, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_S},
	{"type": MenuItemType.BUTTON, "label": CAMPAIGN_MENU_ITEM_RELOAD, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_R},
	{"type": MenuItemType.SEPARATOR},
	{"type": MenuItemType.BUTTON, "label": CAMPAIGN_MENU_ITEM_QUIT, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_Q},
]

signal preferences_audio_pressed
signal preferences_video_pressed

const PREFERENCES_MENU_ITEM_AUDIO := "Audio..."
const PREFERENCES_MENU_ITEM_VIDEO := "Video..."

var preferences_menu_items := [
	{"type": MenuItemType.BUTTON, "label": PREFERENCES_MENU_ITEM_AUDIO, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_U},
	{"type": MenuItemType.BUTTON, "label": PREFERENCES_MENU_ITEM_VIDEO, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_Y},
]

signal help_how_to_start_pressed
signal help_manual_pressed
signal help_about_pressed

const HELP_MENU_ITEM_HOW_TO_START := "How to Start..."
const HELP_MENU_ITEM_MANUAL := "Manual..."
const HELP_MENU_ITEM_ABOUT := "About..."

var help_menu_items := [
	{"type": MenuItemType.BUTTON, "label": HELP_MENU_ITEM_HOW_TO_START, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_COMMA},
	{"type": MenuItemType.BUTTON, "label": HELP_MENU_ITEM_MANUAL, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_M},
	{"type": MenuItemType.SEPARATOR},
	{"type": MenuItemType.BUTTON, "label": HELP_MENU_ITEM_ABOUT, "shortcut": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_O},
]


@onready var campaign_menu: PopupMenu = %Campaing
@onready var preferences_menu: PopupMenu = %Preferences
@onready var help_menu: PopupMenu = %Help

@onready var flow_controller: FlowController = %FlowController
@onready var sound_controller: PanelContainer = %SoundController
@onready var master_volume_controller: VolumeController = %MasterVolumeController


var _campaign_menu_ids := {}
var _preferences_menu_ids := {}
var _help_menu_ids := {}


func _ready() -> void:
	var index := 0
	for item in campaign_menu_items:
		match item.type:
			MenuItemType.SEPARATOR:
				campaign_menu.add_separator(item.get("label", ""), index)
			MenuItemType.BUTTON:
				_campaign_menu_ids[item.label] = index
				campaign_menu.add_item(item.label, index, item.get("shortcut", 0))
		index += 1
	
	index = 0
	for item in preferences_menu_items:
		match item.type:
			MenuItemType.SEPARATOR:
				preferences_menu.add_separator(item.get("label", ""), index)
			MenuItemType.BUTTON:
				_preferences_menu_ids[item.label] = index
				preferences_menu.add_item(item.label, index, item.get("shortcut", 0))
		index += 1
	
	index = 0
	for item in help_menu_items:
		match item.type:
			MenuItemType.SEPARATOR:
				help_menu.add_separator(item.get("label", ""), index)
			MenuItemType.BUTTON:
				_help_menu_ids[item.label] = index
				help_menu.add_item(item.label, index, item.get("shortcut", 0))
		index += 1
	
	campaign_menu.id_pressed.connect(_on_campaing_menu_id_pressed)
	preferences_menu.id_pressed.connect(_on_preferences_menu_id_pressed)
	help_menu.id_pressed.connect(_on_help_menu_id_pressed)
	
	campaign_menu.get_window().transparent = true
	preferences_menu.get_window().transparent = true
	help_menu.get_window().transparent = true
	
	set_profile()
	
	


func set_profile() -> void:
	if Game.campaign:
		var is_master := Game.campaign.is_master
		set_campaing_menu_item_disabled(CAMPAIGN_MENU_ITEM_SETTINGS, not is_master)
		set_campaing_menu_item_disabled(CAMPAIGN_MENU_ITEM_SAVE, not is_master)
		set_campaing_menu_item_disabled(CAMPAIGN_MENU_ITEM_PLAYERS, not is_master)
		set_campaing_menu_item_disabled(CAMPAIGN_MENU_ITEM_RELOAD, false)
		
		set_help_menu_item_disabled(HELP_MENU_ITEM_MANUAL, false)
	else:
		set_campaing_menu_item_disabled(CAMPAIGN_MENU_ITEM_SETTINGS, true)
		set_campaing_menu_item_disabled(CAMPAIGN_MENU_ITEM_SAVE, true)
		set_campaing_menu_item_disabled(CAMPAIGN_MENU_ITEM_PLAYERS, true)
		set_campaing_menu_item_disabled(CAMPAIGN_MENU_ITEM_RELOAD, true)
		
		set_help_menu_item_disabled(HELP_MENU_ITEM_MANUAL, true)
	
	flow_controller.set_profile()
	
	if Game.campaign:
		sound_controller.visible = true
	else:
		sound_controller.visible = false


func _on_campaing_menu_id_pressed(id: int):
	var item_label := campaign_menu.get_item_text(id)
	match item_label:
		CAMPAIGN_MENU_ITEM_NEW: campaign_new_pressed.emit()
		CAMPAIGN_MENU_ITEM_HOST: campaign_host_pressed.emit()
		CAMPAIGN_MENU_ITEM_JOIN: campaign_join_pressed.emit()
		CAMPAIGN_MENU_ITEM_SETTINGS: campaign_settings_pressed.emit()
		CAMPAIGN_MENU_ITEM_PLAYERS: campaign_players_pressed.emit()
		CAMPAIGN_MENU_ITEM_SAVE: campaign_save_pressed.emit()
		CAMPAIGN_MENU_ITEM_RELOAD: campaign_reload_pressed.emit()
		CAMPAIGN_MENU_ITEM_QUIT: campaign_quit_pressed.emit()

func _on_preferences_menu_id_pressed(id: int):
	var item_label := preferences_menu.get_item_text(id)
	match item_label:
		PREFERENCES_MENU_ITEM_AUDIO: preferences_audio_pressed.emit()
		PREFERENCES_MENU_ITEM_VIDEO: preferences_video_pressed.emit()

func _on_help_menu_id_pressed(id: int):
	var item_label := help_menu.get_item_text(id)
	match item_label:
		HELP_MENU_ITEM_HOW_TO_START: help_how_to_start_pressed.emit()
		HELP_MENU_ITEM_MANUAL: help_manual_pressed.emit()
		HELP_MENU_ITEM_ABOUT: help_about_pressed.emit()
		

func _get_campaing_menu_item_index(item_label: String) -> int:
	var index := 0
	for items in campaign_menu_items:
		if items.get("label") == item_label:
			return index
		index += 1
	return -1

func _get_preferences_menu_item_index(item_label: String) -> int:
	var index := 0
	for items in preferences_menu_items:
		if items.get("label") == item_label:
			return index
		index += 1
	return -1

func _get_help_menu_item_index(item_label: String) -> int:
	var index := 0
	for items in help_menu_items:
		if items.get("label") == item_label:
			return index
		index += 1
	return -1


func set_campaing_menu_item_disabled(item_label: String, value: bool):
	var item_index := _get_campaing_menu_item_index(item_label)
	campaign_menu.set_item_disabled(item_index, value)

func set_preferences_menu_item_disabled(item_label: String, value: bool):
	var item_index := _get_preferences_menu_item_index(item_label)
	preferences_menu.set_item_disabled(item_index, value)

func set_help_menu_item_disabled(item_label: String, value: bool):
	var item_index := _get_help_menu_item_index(item_label)
	help_menu.set_item_disabled(item_index, value)
