class_name UI
extends Control

signal save_campaign_button_pressed
signal reload_campaign_button_pressed

@onready var app_music: AudioStreamPlayer = $AppMusic
@onready var home_animation: HomeAnimation = $HomeAnimation
@onready var nav_bar: NavBar = %NavBar
@onready var flow_border: Panel = %FlowBorder
@onready var ide: MarginContainer = %IDE
@onready var mouse_blocker: Control = %MouseBlocker
@onready var corner_windows: Control = %CornerWindows
@onready var new_campaign_window: NewCampaignWindow = %NewCampaignWindow
@onready var host_campaign_window: HostCampaignWindow = %HostCampaignWindow
@onready var join_campaign_window: JoinCampaignWindow = %JoinCampaignWindow
@onready var campaign_players_window: CampaignPlayersWindow = %CampaignPlayersWindow
@onready var how_to_start_window: HowToStartWindow = %HowToStartWindow
@onready var center_windows: CenterContainer = %CenterWindows
@onready var delete_window: DeleteWindow = %DeleteWindow
@onready var exit_window: ExitWindow = %ExitWindow
@onready var audio_preferences_window: AudioPreferencesWindow = %AudioPreferencesWindow
@onready var video_preferences_window: VideoPreferencesWindow = %VideoPreferencesWindow
@onready var credits_window: CreditsWindow = %CreditsWindow

# left section
@onready var left: Control = %Left
@onready var left_up: Control = %LeftUp
@onready var left_down: Control = %LeftDown
@onready var tab_elements: TabElements = %Elements
@onready var tab_players: TabPlayers = %Players
@onready var tab_blueprints: TabBlueprints = %Blueprints
@onready var tab_world: TabWorld = %World
@onready var tab_jukebox: TabJukebox = %Jukebox

# right section
@onready var right: Control = %Right
@onready var right_up: Control = %RightUp
@onready var right_down: Control = %RightDown
@onready var right_down_tabs: Control = %RightDownTabs
@onready var tab_properties: TabProperties = %Properties
@onready var tab_messages: TabMessages = %Messages

# center section
@onready var manual_container: PanelContainer = %ManualContainer
@onready var middle_up: Control = %MiddleUp
@onready var middle_down: Control = %MiddleDown
@onready var scene_tabs: TabContainer = %TabScenes
@onready var scene_coverings: Control = %SceneCoverings
@onready var fade_transition: FadeTransition = %FadeTransition
@onready var master_cover: FadeTransition = %MasterCover
@onready var build_border: Panel = %BuildBorder
@onready var dicer: Dicer = %Dicer

@onready var tab_builder: TabBuilder = %Materials
@onready var tab_resources: TabResources = %Resources
@onready var minimize_down_button: Button = %MinimizeDownButton
@onready var restore_down_button: Button = %RestoreDownButton

# Utilities
@onready var mode_controller: ModeController = %ModeController
@onready var label_vision_button: Button = %LabelVisionButton
@onready var darkvision_button: Button = %DarkvisionButton

# debug
@onready var state_label_value: Label = %StateLabelValue
@onready var player_label_value: Label = %PlayerLabelValue


var selected_scene_tab: TabScene :
	get: return scene_tabs.get_current_tab_control() if scene_tabs else null
		
var selected_map: Map :
	get: return selected_scene_tab.map if selected_scene_tab else null
		
var is_mouse_over_scene_tab: bool :
	get: 
		return selected_scene_tab and selected_scene_tab.is_mouse_over
		
var scene_tab_has_focus: bool :
	get: 
		return selected_scene_tab and selected_scene_tab.scene_has_focus and not Game.control_uses_keyboard


var darkvision_enabled: bool :
	get: return darkvision_button.button_pressed

var label_vision_enabled: bool :
	get: return label_vision_button.button_pressed
	

func init() -> UI:
	Game.ui = self
	Game.manager.add_child(self)
	Game.modes = mode_controller
	return self


func _ready() -> void:
	build_border.visible = false
	manual_container.visible = false
	mouse_blocker.visible = false
	
	center_windows.visible = true
	corner_windows.visible = true
	new_campaign_window.visible = false
	host_campaign_window.visible = false
	join_campaign_window.visible = false
	campaign_players_window.visible = false
	how_to_start_window.visible = false
	delete_window.visible = false
	new_campaign_window.close_window.connect(_on_close_window_pressed)
	host_campaign_window.close_window.connect(_on_close_window_pressed)
	join_campaign_window.close_window.connect(_on_close_window_pressed)
	campaign_players_window.close_window.connect(_on_close_window_pressed)
	how_to_start_window.close_window.connect(_on_close_window_pressed)
	delete_window.close_window.connect(_on_close_window_pressed)
	exit_window.close_window.connect(_on_close_window_pressed)
	audio_preferences_window.close_window.connect(_on_close_window_pressed)
	video_preferences_window.close_window.connect(_on_close_window_pressed)
	credits_window.close_window.connect(_on_close_window_pressed)
	mouse_blocker.gui_input.connect(remove_mouse_blocker)
	
	tab_properties.settings.info_changed.connect(_on_info_changed)
	
	minimize_down_button.pressed.connect(_on_minimize_down_pressed.bind(true))
	restore_down_button.pressed.connect(_on_minimize_down_pressed.bind(false))
	
	label_vision_button.pressed.connect(_on_label_vision_button_pressed)
	darkvision_button.pressed.connect(_on_darkvision_button_pressed)
	
	nav_bar.campaign_new_pressed.connect(_on_campaign_new_pressed)
	nav_bar.campaign_host_pressed.connect(_on_campaign_host_pressed)
	nav_bar.campaign_join_pressed.connect(_on_campaign_join_pressed)
	nav_bar.campaign_settings_pressed.connect(_on_campaign_settings_pressed)
	nav_bar.campaign_players_pressed.connect(_on_campaign_players_pressed)
	nav_bar.campaign_save_pressed.connect(_on_campaign_save_pressed)
	nav_bar.campaign_reload_pressed.connect(_on_campaign_reload_pressed)
	nav_bar.campaign_quit_pressed.connect(_on_campaign_quit_pressed)
	
	nav_bar.preferences_audio_pressed.connect(_on_preferences_audio_pressed)
	nav_bar.preferences_video_pressed.connect(_on_preferences_video_pressed)
	
	nav_bar.help_how_to_start_pressed.connect(_on_help_how_to_start_pressed)
	nav_bar.help_manual_pressed.connect(_on_help_manual_pressed)
	nav_bar.help_about_pressed.connect(_on_help_about_pressed)
	
	home_animation.start()
	Game.manager.campaign_loaded.connect(home_animation.stop)
	app_music.finished.connect(app_music.play)
	Game.manager.campaign_loaded.connect(app_music.stop)
	
	

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


func _on_info_changed(label: String, description: String):
	selected_scene_tab.name = label
	selected_map.label = label
	selected_map.description = description


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


func _on_campaign_players_pressed():
	mouse_blocker.visible = true
	campaign_players_window.visible = true


func _on_campaign_save_pressed():
	save_campaign_button_pressed.emit()
	
	
func _on_campaign_reload_pressed():
	save_campaign_button_pressed.emit()
	
	## finish ongoing rpcs
	await get_tree().process_frame
	
	reload_campaign_button_pressed.emit()


func _on_campaign_quit_pressed():
	quit()


func _on_preferences_audio_pressed():
	audio_preferences_window.visible = true


func _on_preferences_video_pressed():
	video_preferences_window.visible = true


func _on_help_how_to_start_pressed():
	how_to_start_window.visible = true
	join_campaign_window.refresh()


func _on_help_manual_pressed():
	manual_container.visible = true


func _on_help_about_pressed():
	credits_window.visible = true


func quit():
	Game.manager.safe_quit()


func _on_darkvision_button_pressed():
	Game.ui.selected_map.is_darkvision_view = darkvision_enabled
	

func _on_label_vision_button_pressed():
	Game.ui.selected_map.label_vision_enabled.emit(label_vision_enabled)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_Q:
				if Game.campaign:
					darkvision_button.button_pressed = not darkvision_button.button_pressed
					_on_darkvision_button_pressed()
			if event.keycode == KEY_N:
				if Game.campaign:
					label_vision_button.button_pressed = not label_vision_button.button_pressed
					_on_label_vision_button_pressed()
	
