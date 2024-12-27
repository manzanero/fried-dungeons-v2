class_name FlowController
extends PanelContainer

const SCENE := preload("res://ui/flow_controller/flow_controller.tscn")

const PAUSE_COLOR := Color(0.443, 0.408, 0.292)
const STOP_COLOR := Color(0.511, 0.245, 0.236)
enum State {NONE, PLAYING, PAUSED, STOPPED}

signal played
signal paused
signal stopped
signal changed


var flow_border := preload("res://ui/flow_controller/flow_border.tres")


var state: State
var is_paused: bool
var is_stopped: bool


@onready var play_button: Button = %PlayButton
@onready var pause_button: Button = %PauseButton
@onready var stop_button: Button = %StopButton


func set_profile() -> void:
	if Game.campaign:
		visible = true
		if Game.campaign.is_master:
			play_button.mouse_filter = Control.MOUSE_FILTER_STOP
			pause_button.mouse_filter = Control.MOUSE_FILTER_STOP
			stop_button.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			play_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pause_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stop_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		visible = false


func _ready() -> void:
	play_button.set_pressed_no_signal(not is_paused)
	play_button.pressed.connect(_on_play_button_pressed)
	pause_button.set_pressed_no_signal(is_paused)
	pause_button.pressed.connect(_on_paused_button_pressed)
	stop_button.set_pressed_no_signal(is_stopped)
	stop_button.pressed.connect(_on_stop_button_pressed)
	flow_border.border_color = Color.TRANSPARENT


func _on_play_button_pressed() -> void:
	change_flow_state(State.PLAYING)
	Game.server.rpcs.change_flow_state.rpc(State.PLAYING)

func _on_paused_button_pressed() -> void:
	change_flow_state(State.PAUSED)
	Game.server.rpcs.change_flow_state.rpc(State.PAUSED)

func _on_stop_button_pressed() -> void:
	change_flow_state(State.STOPPED)
	Game.server.rpcs.change_flow_state.rpc(State.STOPPED)
	

func change_flow_state(_state: State):
	state = _state
	play_button.set_pressed_no_signal(false)
	pause_button.set_pressed_no_signal(false)
	stop_button.set_pressed_no_signal(false)
	match state:
		State.PLAYING: 
			play()
			play_button.set_pressed_no_signal(true)
		State.PAUSED: 
			pause()
			pause_button.set_pressed_no_signal(true)
		State.STOPPED: 
			stop()
			stop_button.set_pressed_no_signal(true)


func play() -> void:
	state = State.PLAYING
	is_paused = false
	is_stopped = false
	played.emit()
	changed.emit()
	play_button.set_pressed_no_signal(true)
	pause_button.set_pressed_no_signal(false)
	stop_button.set_pressed_no_signal(false)
	Game.ui.flow_border.visible = false
	Game.ui.master_cover.uncover(0)
	
func pause() -> void:
	state = State.PAUSED
	is_paused = true
	is_stopped = false
	paused.emit()
	changed.emit()
	play_button.set_pressed_no_signal(false)
	pause_button.set_pressed_no_signal(true)
	stop_button.set_pressed_no_signal(false)
	flow_border.border_color = PAUSE_COLOR
	Game.ui.flow_border.visible = true
	Game.ui.master_cover.uncover(0)

func stop() -> void:
	state = State.STOPPED
	is_paused = true
	is_stopped = true
	stopped.emit()
	changed.emit()
	play_button.set_pressed_no_signal(false)
	pause_button.set_pressed_no_signal(false)
	stop_button.set_pressed_no_signal(true)
	flow_border.border_color = STOP_COLOR
	Game.ui.flow_border.visible = true
	if not Game.campaign.is_master:
		Game.ui.master_cover.cover(0)
	
