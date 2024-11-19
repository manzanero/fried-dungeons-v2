class_name UI
extends Control

signal save_campaign_button_pressed
signal reload_campaign_pressed


# nav bar
@onready var nav_bar: PanelContainer = %NavBar
@onready var nav_campaing: PopupMenu = %Campaing
@onready var nav_preferences: PopupMenu = %Preferences
@onready var nav_help: PopupMenu = %Help
@onready var flow_controller: FlowController = %FlowController

@onready var flow_border: Panel = %FlowBorder
@onready var ide: MarginContainer = %IDE
@onready var main_menu: MainMenu = %MainMenu

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
@onready var tab_instancer: TabInstancer = %Instancer
@onready var minimize_down_button: Button = %MinimizeDownButton
@onready var restore_down_button: Button = %RestoreDownButton


var selected_scene_tab: TabScene :
	get: return scene_tabs.get_current_tab_control() if scene_tabs else null
		
var selected_map: Map :
	get: return selected_scene_tab.map if selected_scene_tab else null
		
var is_mouse_over_scene_tab: bool :
	get: return selected_scene_tab.is_mouse_over and not main_menu.visible


func _ready() -> void:
	nav_campaing.id_pressed.connect(_on_nav_campaing_id_pressed)
	nav_campaing.set_item_shortcut(0, Utils.action_shortcut("save"))
	
	tab_settings.info_changed.connect(_on_info_changed)
	
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
	if Game.campaign.is_master:
		Game.manager.save_campaign()
		
	if Game.server.peer:
		Game.server.peer.close()
	
	main_menu.scan_campaigns()
	main_menu.scan_servers()
	main_menu.visible = true


func reload_campaign():
	if Game.campaign.is_master:
		Game.manager.save_campaign()
	
	# finish ongoing rpcs
	await get_tree().process_frame
	
	reload_campaign_pressed.emit()


func quit():
	if Game.campaign.is_master:
		Game.manager.save_campaign()
		
	get_tree().quit()


func _on_info_changed(label: String):
	selected_scene_tab.name = label
	selected_map.label = label


func _on_minimize_down_pressed(minimize: bool):
	minimize_down_button.visible = not minimize
	restore_down_button.visible = minimize
	middle_down.visible = not minimize
	
