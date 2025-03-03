class_name FlowController
extends PanelContainer

const SCENE := preload("res://ui/flow_controller/flow_controller.tscn")

const PLAY_COLOR := Color(0.159, 0.3, 0.282)
const PAUSE_COLOR := Color(0.436, 0.4, 0.285)
const STOP_COLOR := Color(0.416, 0.214, 0.209)
enum State {NONE, PLAYING, PAUSED, STOPPED}

signal played
signal paused
signal stopped
signal changed


var flow_border := preload("res://ui/flow_controller/flow_border.tres")


var state: State
var is_paused: bool
var is_stopped: bool

var players_flow_aligned := false :
	set(value): 
		players_flow_aligned = value
		reset_button.disabled = value

var players_in_scene := false :
	set(value): 
		players_in_scene = value
		scene_button.disabled = value

@onready var play_button: Button = %PlayButton
@onready var pause_button: Button = %PauseButton
@onready var stop_button: Button = %StopButton

@onready var reset_button: Button = %ResetButton
@onready var scene_button: Button = %SceneButton


func set_profile() -> void:
	if Game.campaign:
		visible = true
		if Game.campaign.is_master:
			reset_button.mouse_filter = Control.MOUSE_FILTER_STOP
			play_button.mouse_filter = Control.MOUSE_FILTER_STOP
			pause_button.mouse_filter = Control.MOUSE_FILTER_STOP
			stop_button.mouse_filter = Control.MOUSE_FILTER_STOP
			scene_button.mouse_filter = Control.MOUSE_FILTER_STOP
			
			reset_button.visible = true
			scene_button.visible = true
		else:
			reset_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			play_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pause_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stop_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			scene_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			reset_button.visible = false
			scene_button.visible = false
	else:
		visible = false


func _ready() -> void:
	Game.flow = self
	
	reset_button.pressed.connect(_on_reset_button_pressed)
	scene_button.pressed.connect(_on_scene_button_pressed)
	
	play_button.set_pressed_no_signal(not is_paused)
	play_button.pressed.connect(_on_play_button_pressed)
	pause_button.set_pressed_no_signal(is_paused)
	pause_button.pressed.connect(_on_paused_button_pressed)
	stop_button.set_pressed_no_signal(is_stopped)
	stop_button.pressed.connect(_on_stop_button_pressed)
	#flow_border.border_color = Color.TRANSPARENT
	flow_border.border_color = PLAY_COLOR
	
	changed.connect(func (): 
		var root := Game.ui.tab_players.players_tree.get_root()
		if root:
			Game.ui.tab_players._set_flow(root, state)
	)


func _on_reset_button_pressed() -> void:
	Game.ui.tab_players.reset_all_players()
	players_flow_aligned = true


func _on_scene_button_pressed() -> void:
	Game.ui.tab_world.send_players_to_map(Game.ui.selected_map.slug)
	Game.manager.refresh_tabs()
	players_in_scene = true


func _on_play_button_pressed() -> void:
	change_flow_state(State.PLAYING)
	Game.server.rpcs.change_flow_state.rpc(State.PLAYING, Game.ui.tab_players.get_data())

func _on_paused_button_pressed() -> void:
	change_flow_state(State.PAUSED)
	Game.server.rpcs.change_flow_state.rpc(State.PAUSED, Game.ui.tab_players.get_data())

func _on_stop_button_pressed() -> void:
	change_flow_state(State.STOPPED)
	Game.server.rpcs.change_flow_state.rpc(State.STOPPED, Game.ui.tab_players.get_data())
	

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
	flow_border.bg_color = PLAY_COLOR
	#Game.ui.flow_border.visible = false
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
	#flow_border.border_color = PAUSE_COLOR
	flow_border.bg_color = PAUSE_COLOR
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
	flow_border.bg_color = STOP_COLOR
	#flow_border.border_color = STOP_COLOR
	Game.ui.flow_border.visible = true
	if not Game.campaign.is_master:
		Game.ui.master_cover.cover(0)


func _unhandled_input(event: InputEvent) -> void:
	if not Game.player_is_master:
		return

	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_SPACE:
				if Game.control_uses_keyboard:
					return
				if not is_paused:
					pause()
					return
				if is_paused:
					play()
					return
