extends HBoxContainer


@onready var master_mute_volume: TextureButton = %MasterMuteVolume
@onready var master_volume_slider: HSlider = %MasterVolumeSlider


var _dragged := false


func _ready() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(1))
	master_volume_slider.set_value_no_signal(100)
	master_volume_slider.drag_started.connect(_on_slider_drag_started)
	master_volume_slider.drag_ended.connect(_on_slider_drag_ended)
	master_mute_volume.set_pressed_no_signal(false)
	master_mute_volume.pressed.connect(_on_mute_volume_pressed)

func _on_slider_drag_started() -> void:
	_dragged = true

func _on_slider_drag_ended(_value_changed: bool) -> void:
	_dragged = false


func _process(_delta: float) -> void:
	if _dragged:
		var volume := linear_to_db(master_volume_slider.value / 100.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume)


func _on_mute_volume_pressed() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), master_mute_volume.button_pressed)
