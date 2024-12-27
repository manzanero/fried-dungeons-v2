class_name TabJukebox
extends Control

const SOUND_ICON := preload("res://resources/icons/sound_icon.png")
const STOP_ICON := preload("res://resources/icons/stop_icon.png")
const PLAY_ICON := preload("res://resources/icons/play_icon.png")
const LOOP_ICON := preload("res://resources/icons/reload_icon.png")

var root: TreeItem
var now_playing: Array[TreeItem] = []
var muted: bool :
	set(value): mute_button.button_pressed = value; mute_button.pressed.emit()
	get: return mute_button.button_pressed

var item_selected: TreeItem :
	get: return tree.get_selected() if is_instance_valid(tree.get_selected()) else null

var sound_selected: CampaignResource :
	get: return item_resource(item_selected) if item_selected else null
	
func item_resource(item: TreeItem) -> CampaignResource:
	return item.get_metadata(0)

var music_items := {}

@onready var audio: Audio = %Audio
@onready var mute_button: Button = %MuteButton
@onready var stop_button: Button = %StopButton
@onready var tree: DraggableTree = %DraggableTree
@onready var resouce_button: Button = %ResouceButton
@onready var import_button: Button = %ImportButton
@onready var clear_button: Button = %ClearButton


func _ready() -> void:
	reset()
	
	audio.finished.connect(_on_audio_finished)
	
	tree.item_activated.connect(_on_item_activated)
	tree.button_clicked.connect(_on_button_clicked)
	tree.item_mouse_selected.connect(_on_item_mouse_selected)
	
	mute_button.button_pressed = false
	_on_mute_button_pressed()
	mute_button.pressed.connect(_on_mute_button_pressed)
	stop_button.pressed.connect(_on_stop_button_pressed)
	
	resouce_button.pressed.connect(_on_resouce_button_pressed)
	import_button.pressed.connect(_on_import_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	
	#tree.drop_origins_allowed = ["campaign_resouce_item_list"]
	#tree.drop_types_allowed = ["campaign_resouce_item"]
	tree.items_dropped.connect(_on_items_dropped)
	

func _on_audio_finished():
	if not Game.campaign or not Game.campaign.is_master:
		return
	
	var sound_playing = now_playing[0]
	if not is_instance_valid(sound_playing):  # sometimes item is freed
		return
		
	var sound_item: TreeItem = sound_playing
	var sound := item_resource(sound_item)
	if sound.attributes.get("loop"):
		audio.play()
		Game.server.rpcs.play_theme_song.rpc(sound.path, muted)
	else:
		_set_playing(sound_item, false)


func add_sound(sound: CampaignResource, from_position := 0.0) -> TreeItem:
	var music_path := sound.file_basename  # TODO jukenox path
	
	# insert alphabetically
	var index := 0
	for child in root.get_children():
		if music_path == child.get_text(0):
			return
		if music_path < child.get_text(0):
			break
		index += 1
	var music_item := root.create_child(index)
	
	#music_item.set_editable(0, true)
	music_item.set_text(0, music_path)
	music_item.set_tooltip_text(0, sound.path)
	music_item.set_metadata(0, sound)
	
	music_item.add_button(0, PLAY_ICON, 0)
	music_item.set_button_tooltip_text(0, 0, "Play this music for all players")
	music_item.set_button_color(0, 0, Color.DARK_GRAY)
	if from_position:
		_set_playing(music_item, true, from_position)
	
	music_items[music_path] = music_item
	
	if Game.campaign.is_master:
		Utils.safe_connect(sound.resource_changed, _on_sound_changed.bind(sound))
	
	return music_item
	

func _on_sound_changed(sound: CampaignResource):
	for music_item in now_playing:
		if item_resource(music_item) == sound:
			set_audio_attributes(sound)
			break


func set_audio_attributes(sound: CampaignResource):
	audio.volume_db = linear_to_db(sound.attributes.get("volume", ImportSound.DEFAULT_VOLUME))
	audio.pitch_scale = sound.attributes.get("pitch", ImportSound.DEFAULT_PITCH)
	
	Game.server.rpcs.change_theme.rpc(db_to_linear(audio.volume_db), audio.pitch_scale)
	

func get_data():
	var music := {}
	for music_item in root.get_children():
		var music_path := music_item.get_text(0)
		var sound := item_resource(music_item)
		var music_data := {
			"resource": sound.path,
		}
		if music_item in now_playing:
			music_data["position"] = snappedf(audio.sound_position, 0.001)
			
		music[music_path] = music_data
	
	return {
		"muted": muted,
		"music": music,
	}


func _on_item_activated():
	if not sound_selected: return
	
	var resources_tab := Game.ui.tab_resources
	resources_tab.visible = true
	var resource_item := resources_tab.resource_items.get(sound_selected.path) as TreeItem
	resource_item.uncollapse_tree()
	resource_item.select(0)
	var resource_tree := resource_item.get_tree()
	resource_tree.item_activated.emit()
	

func _set_playing(sound_item: TreeItem, is_playing: bool, from_position := 0.0) -> void:
	var sound := item_resource(sound_item)
	if is_playing and not FileAccess.file_exists(sound.abspath):
		Utils.temp_tooltip("This file no longer exists")
		return
		
	if is_playing:
		sound_item.set_button_color(0, 0, Color.GREEN)
		set_audio_attributes(sound)
		if sound_item not in now_playing:
			now_playing.append(sound_item)
			audio.file_path = sound.abspath
			audio.play(from_position)
	else:
		sound_item.set_button_color(0, 0, Color.DARK_GRAY)
		if sound_item in now_playing:
			now_playing.erase(sound_item)
			audio.stop()


func _on_button_clicked(item: TreeItem, column: int, _id: int, _mouse_button_index: int) -> void:
	item.select(column)
	if item in now_playing: 
		_set_playing(item, false)
		Game.server.rpcs.play_theme_song.rpc("")
		return
		
	for child_item in root.get_children(): 
		_set_playing(child_item, false)
	_set_playing(item, true)
	Game.server.rpcs.play_theme_song.rpc(item_resource(item).path, muted)
	

func _on_item_mouse_selected(_mouse_position: Vector2, mouse_button_index: int):
	item_selected = tree.get_selected()
	
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		_on_clear_button_pressed()


func _on_mute_button_pressed() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Jukebox"), muted)
	if muted:
		Game.server.rpcs.change_theme.rpc(0, audio.pitch_scale)
	else:
		Game.server.rpcs.change_theme.rpc(db_to_linear(audio.volume_db), audio.pitch_scale)


func _on_stop_button_pressed() -> void:
	for sound_item in now_playing:
		#if is_instance_valid(sound_item):
			_set_playing(sound_item, false)
	Game.server.rpcs.play_theme_song.rpc("")
	Debug.print_info_message("Song \"%s\" stopped")
	

func _on_resouce_button_pressed():
	if not item_selected:
		Game.ui.tab_resources.visible = true
		return
	
	_on_item_activated()


func _on_import_button_pressed():
	var resources_tab := Game.ui.tab_resources
	var resource: CampaignResource = resources_tab.resource_selected
	if not resource or resource.resource_type != CampaignResource.Type.SOUND:
		resources_tab.visible = true
		Utils.temp_tooltip("Select a Sound", 1)
		return
	
	var sound_item := add_sound(resource)
	if not sound_item:
		Utils.temp_tooltip("Sound already in list", 1)
		Debug.print_info_message("Sound already in list: \"%s\"" % resource.path)
		return
		
	sound_item.select(0)
	Game.server.rpcs.load_theme_song.rpc(resource.path)
	
	Debug.print_info_message("Sound added: \"%s\"" % resource.path)


func _on_clear_button_pressed():
	if not item_selected: 
		return
	
	for sound_item in now_playing:
		_set_playing(sound_item, false)
		Game.server.rpcs.play_theme_song.rpc("")
		Debug.print_info_message("Song \"%s\" stopped")
	
	
	
	item_selected.free()
	Debug.print_info_message("Song \"%s\" removed")


func _on_items_dropped(drop_data: Dictionary, _parent_item: TreeItem, _item_index: int):
	var sounds := []
	for item in drop_data.items:
		var resource: CampaignResource = item.get_metadata(0)
		sounds.append(resource)
		if resource.resource_type != CampaignResource.Type.SOUND:
			Utils.temp_tooltip("Cannot add a non sound resource: %s" % resource.path)
			return

	for sound in sounds:
		var sound_item := add_sound(sound)
		if sound_item:
			Game.server.rpcs.load_theme_song.rpc(sound.path)
			Debug.print_info_message("Sound added: \"%s\"" % sound.path)
	

func reset():
	music_items.clear()
	tree.clear()
	root = tree.create_item()
	root.set_text(0, "Music")
