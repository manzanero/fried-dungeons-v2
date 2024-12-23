class_name UI
extends Control

signal save_campaign_button_pressed
signal reload_campaign_button_pressed

static var SCENE := preload("res://ui/ui.tscn")

@onready var nav_bar: NavBar = %NavBar
@onready var flow_border: Panel = %FlowBorder
@onready var ide: MarginContainer = %IDE
@onready var mouse_blocker: Control = %MouseBlocker
@onready var corner_windows: Control = %CornerWindows
@onready var new_campaign_window: NewCampaignWindow = %NewCampaignWindow
@onready var host_campaign_window: HostCampaignWindow = %HostCampaignWindow
@onready var join_campaign_window: JoinCampaignWindow = %JoinCampaignWindow
@onready var center_windows: CenterContainer = %CenterWindows
@onready var delete_element_window: DeleteElementWindow = %DeleteElementWindow

# left section
@onready var left: Control = %Left
@onready var left_up: Control = %LeftUp
@onready var left_down: Control = %LeftDown
@onready var tab_elements: TabElements = %Elements
@onready var tab_jukebox: TabJukebox = %Jukebox
@onready var tab_world: TabWorld = %World
@onready var tab_players: TabPlayers = %Players

# right section
@onready var right: Control = %Right
@onready var right_up: Control = %RightUp
@onready var right_down: Control = %RightDown
@onready var right_down_tabs: Control = %RightDownTabs
@onready var tab_properties: TabProperties = %Properties
@onready var tab_settings: TabSettings = %Settings
@onready var tab_messages: TabMessages = %Messages

# center section
@onready var middle_up: Control = %MiddleUp
@onready var middle_down: Control = %MiddleDown
@onready var scene_tabs: TabContainer = %TabScenes
@onready var scene_coverings: Control = %SceneCoverings
@onready var fade_transition: FadeTransition = %FadeTransition
@onready var master_cover: FadeTransition = %MasterCover
@onready var build_border: Panel = %BuildBorder
@onready var dicer: Dicer = %Dicer
@onready var state_label_value: Label = %StateLabelValue
@onready var player_label_value: Label = %PlayerLabelValue
@onready var tab_builder: TabBuilder = %Builder
@onready var tab_resources: TabResources = %Resources
@onready var minimize_down_button: Button = %MinimizeDownButton
@onready var restore_down_button: Button = %RestoreDownButton


var selected_scene_tab: TabScene :
	get: return scene_tabs.get_current_tab_control() if scene_tabs else null
		
var selected_map: Map :
	get: return selected_scene_tab.map if selected_scene_tab else null
		
var is_mouse_over_scene_tab: bool :
	get: return selected_scene_tab.is_mouse_over


func init() -> UI:
	Game.ui = self
	Game.manager.add_child(self)
	return self


func _ready() -> void:
	build_border.visible = false
	mouse_blocker.visible = false
	
	center_windows.visible = true
	corner_windows.visible = true
	new_campaign_window.visible = false
	host_campaign_window.visible = false
	join_campaign_window.visible = false
	delete_element_window.visible = false
	new_campaign_window.close_window.connect(_on_close_window_pressed)
	host_campaign_window.close_window.connect(_on_close_window_pressed)
	join_campaign_window.close_window.connect(_on_close_window_pressed)
	delete_element_window.close_window.connect(_on_close_window_pressed)
	mouse_blocker.gui_input.connect(remove_mouse_blocker)
	
	tab_settings.info_changed.connect(_on_info_changed)
	
	minimize_down_button.pressed.connect(_on_minimize_down_pressed.bind(true))
	restore_down_button.pressed.connect(_on_minimize_down_pressed.bind(false))
	
	nav_bar.campaign_new_pressed.connect(_on_campaign_new_pressed)
	nav_bar.campaign_host_pressed.connect(_on_campaign_host_pressed)
	nav_bar.campaign_join_pressed.connect(_on_campaign_join_pressed)
	nav_bar.campaign_settings_pressed.connect(_on_campaign_settings_pressed)
	nav_bar.campaign_save_pressed.connect(_on_campaign_save_pressed)
	nav_bar.campaign_reload_pressed.connect(_on_campaign_reload_pressed)
	nav_bar.campaign_quit_pressed.connect(_on_campaign_quit_pressed)
	

func remove_mouse_blocker(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		for window: FriedWindow in corner_windows.get_children() + center_windows.get_children():
			window.close_button.pressed.emit()

func _on_close_window_pressed():
	mouse_blocker.visible = is_any_visible_child()
	
func is_any_visible_child():
	for child in corner_windows.get_children() + center_windows.get_children():
		if child.visible:
			return true
	return false


func _on_info_changed(label: String):
	selected_scene_tab.name = label
	selected_map.label = label


func _on_minimize_down_pressed(minimize: bool):
	minimize_down_button.visible = not minimize
	restore_down_button.visible = minimize
	middle_down.visible = not minimize


func _on_campaign_new_pressed():
	mouse_blocker.visible = true
	new_campaign_window.visible = true


func _on_campaign_host_pressed():
	mouse_blocker.visible = true
	host_campaign_window.visible = true
	host_campaign_window.refresh()


func _on_campaign_join_pressed():
	mouse_blocker.visible = true
	join_campaign_window.visible = true
	join_campaign_window.refresh()


func _on_campaign_settings_pressed():
	pass


func _on_campaign_save_pressed():
	save_campaign_button_pressed.emit()
	
	
func _on_campaign_reload_pressed():
	save_campaign_button_pressed.emit()
	
	## finish ongoing rpcs
	await get_tree().process_frame
	
	reload_campaign_button_pressed.emit()


func _on_campaign_quit_pressed():
	quit()


func quit():
	if Game.campaign and Game.campaign.is_master:
		Game.manager.save_campaign()
		
	get_tree().quit()
