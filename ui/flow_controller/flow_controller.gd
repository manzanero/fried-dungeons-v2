class_name FlowController
extends PanelContainer

const PAUSE_COLOR := Color(0.443, 0.408, 0.292)
const STOP_COLOR := Color(0.393, 0.29, 0.264)
enum STATE {PLAYING, PAUSED, STOPPED}

signal played
signal paused
signal stopped
signal changed


var flow_border := preload("res://ui/flow_controller/flow_border.tres")


var state: STATE
var is_paused: bool
var is_stopped: bool


@onready var play_button: Button = %PlayButton
@onready var pause_button: Button = %PauseButton
@onready var stop_button: Button = %StopButton
@onready var player_blocker: Control = %PlayerBlocker


func _ready() -> void:
	play_button.set_pressed_no_signal(not is_paused)
	play_button.pressed.connect(_on_play_button_pressed)
	pause_button.set_pressed_no_signal(is_paused)
	pause_button.pressed.connect(_on_paused_button_pressed)
	stop_button.set_pressed_no_signal(is_stopped)
	stop_button.pressed.connect(_on_stop_button_pressed)
	flow_border.border_color = Color.TRANSPARENT


func _on_play_button_pressed() -> void:
	change_flow_state(STATE.PLAYING)
	Game.server.rpcs.change_flow_state.rpc(STATE.PLAYING)

func _on_paused_button_pressed() -> void:
	change_flow_state(STATE.PAUSED)
	Game.server.rpcs.change_flow_state.rpc(STATE.PAUSED)

func _on_stop_button_pressed() -> void:
	change_flow_state(STATE.STOPPED)
	Game.server.rpcs.change_flow_state.rpc(STATE.STOPPED)
	

func change_flow_state(_state: STATE):
	state = _state
	play_button.set_pressed_no_signal(false)
	pause_button.set_pressed_no_signal(false)
	stop_button.set_pressed_no_signal(false)
	match state:
		STATE.PLAYING: 
			play()
			play_button.set_pressed_no_signal(true)
		STATE.PAUSED: 
			pause()
			pause_button.set_pressed_no_signal(true)
		STATE.STOPPED: 
			stop()
			stop_button.set_pressed_no_signal(true)


func play() -> void:
	is_paused = false
	is_stopped = false
	played.emit()
	changed.emit()
	Game.ui.flow_border.visible = false
	Game.ui.master_cover.uncover(0)
	
func pause() -> void:
	is_paused = true
	is_stopped = false
	paused.emit()
	changed.emit()
	flow_border.border_color = PAUSE_COLOR
	Game.ui.flow_border.visible = true
	Game.ui.master_cover.uncover(0)

func stop() -> void:
	is_paused = true
	is_stopped = true
	stopped.emit()
	changed.emit()
	flow_border.border_color = STOP_COLOR
	Game.ui.flow_border.visible = true
	if not Game.campaign.is_master:
		Game.ui.master_cover.cover(0)
	
