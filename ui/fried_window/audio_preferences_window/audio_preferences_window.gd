class_name AudioPreferencesWindow
extends FriedWindow


signal audio_prefernces_changed


var master_volume: float :
	set(value): master_volume_field.property_value = value * 100; _on_audio_preferences_changed()
	get: return master_volume_field.property_value / 100
var app_music: bool :
	set(value): app_music_field.property_value = value; _on_audio_preferences_changed()
	get: return app_music_field.property_value
var scene_sounds: bool :
	set(value): scene_sounds_field.property_value = value; _on_audio_preferences_changed()
	get: return scene_sounds_field.property_value
var scene_volume: float :
	set(value): scene_volume_field.property_value = value * 100; _on_audio_preferences_changed()
	get: return scene_volume_field.property_value / 100


@onready var master_volume_field: FloatField = %MasterVolume
@onready var app_music_field: BoolField = %AppMusic
@onready var scene_sounds_field: BoolField = %SceneSounds
@onready var scene_volume_field: FloatField = %SceneVolume


func _ready() -> void:
	super._ready()
	Game.audio_preferences = self
	read_preferences()
	master_volume_field.value_changed.connect(_on_audio_preferences_changed.unbind(2))
	master_volume_field.value_changed.connect(_on_master_volume_changed.unbind(2))
	app_music_field.value_changed.connect(_on_audio_preferences_changed.unbind(2))
	app_music_field.value_changed.connect(_on_app_music_changed.unbind(2))
	scene_sounds_field.value_changed.connect(_on_audio_preferences_changed.unbind(2))
	scene_sounds_field.value_changed.connect(_on_scene_sounds_changed.unbind(2))
	scene_volume_field.value_changed.connect(_on_audio_preferences_changed.unbind(2))
	scene_volume_field.value_changed.connect(_on_scene_volume_changed.unbind(2))
	visibility_changed.connect(_on_visibility_changed)
	
	#Game.manager.campaign_loaded.connect(func ():
		#Game.ui.nav_bar.master_volume_controller.set_scene_volume(not scene_sounds, scene_volume)
	#)
	

func _on_visibility_changed() -> void:
	if visible:
		Game.ui.mouse_blocker.visible = true


func _on_master_volume_changed():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))

func _on_app_music_changed() -> void:
	if app_music:
		if not Game.campaign:
			Game.ui.app_music.play()
	else:
		Game.ui.app_music.stop()
		

func _on_scene_sounds_changed() -> void:
	var volume_controller := Game.ui.nav_bar.master_volume_controller
	volume_controller.master_mute_volume.button_pressed = not scene_sounds
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Scene"), not scene_sounds)

func _on_scene_volume_changed() -> void:
	var volume_controller := Game.ui.nav_bar.master_volume_controller
	volume_controller.master_volume_slider.value = scene_volume * 100
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Scene"), linear_to_db(scene_volume))


var scheduled_save := false

func _on_audio_preferences_changed() -> void:
	audio_prefernces_changed.emit()
	
	if scheduled_save:
		return
		
	scheduled_save = true
	get_tree().create_timer(1).timeout.connect(func ():
		scheduled_save = false
		save()
	)


func save():
	Utils.dump_json("user://preferences/audio.json", {
		"master_volume": master_volume,
		"app_music": app_music,
		"scene_sounds": scene_sounds,
		"scene_volume": scene_volume,
	}, 2)
	
	
func read_preferences():
	var audio_preferences = Utils.load_json("user://preferences/audio.json")
	master_volume = audio_preferences.get("master_volume", 0.75)
	app_music = audio_preferences.get("app_music", true)
	scene_sounds = audio_preferences.get("scene_sounds", true) 
	scene_volume = audio_preferences.get("scene_volume", 0.75)
