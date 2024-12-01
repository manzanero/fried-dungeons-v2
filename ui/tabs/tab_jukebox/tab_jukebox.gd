class_name TabJukebox
extends Control

const SOUND_ICON := preload("res://resources/icons/sound_icon.png")
const STOP_ICON := preload("res://resources/icons/stop_icon.png")
const PLAY_ICON := preload("res://resources/icons/play_icon.png")
const LOOP_ICON := preload("res://resources/icons/reload_icon.png")

var root: TreeItem
var now_playing := []
var muted: bool :
	set(value): mute_button.button_pressed = value; mute_button.pressed.emit()
	get: return mute_button.button_pressed

var item_selected: TreeItem :
	get: return tree.get_selected() if is_instance_valid(tree.get_selected()) else null

var sound_selected: CampaignResource :
	get: return item_resource(item_selected) if item_selected else null
	
func item_resource(item: TreeItem) -> CampaignResource:
	return item.get_metadata(1)

var sound_items := {}

@onready var audio: Audio = %Audio
@onready var mute_button: Button = %MuteButton
@onready var stop_button: Button = %StopButton
@onready var tree: DraggableTree = %DraggableTree
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
	
	import_button.pressed.connect(_on_import_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	
	tree.items_moved.connect(_on_items_moved)
	
	tree.set_column_title(0, "  ∞")
	tree.set_column_title(1, "  Theme")
	tree.set_column_expand(0, false)
	tree.set_column_expand(1, true)
	tree.set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
	tree.set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_LEFT)
	
	
func _on_audio_finished():
	if not Game.campaign.is_master:
		return
	
	var sound_playing = now_playing[0]
	if not is_instance_valid(sound_playing):  # sometimes item is freed
		return
		
	var sound_item: TreeItem = sound_playing
	if sound_item.is_checked(0):
		audio.play()
		Game.server.rpcs.play_theme_song.rpc(item_resource(sound_item).path, muted)
	else:
		_set_playing(sound_item, false)


func add_sound(sound: CampaignResource, loop := false, from_position := 0.0) -> TreeItem:
	var sound_item := root.create_child()
	
	sound_item.set_editable(0, true)
	sound_item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	sound_item.set_selectable(0, false)
	sound_item.set_checked(0, loop)
	
	sound_item.set_text(1, "%s" % sound.file_basename)
	sound_item.set_tooltip_text(1, sound.path)
	sound_item.set_metadata(1, sound)
	
	sound_item.add_button(1, PLAY_ICON, 0)
	sound_item.set_button_color(1, 0, Color.DARK_GRAY)
	if from_position:
		_set_playing(sound_item, true, from_position)
	
	sound_items[sound.path] = sound_item
	
	sound.resource_changed.connect(func (): _on_sound_changed(sound_item))
	
	return sound_item
	

func _on_sound_changed(sound_item):
	var sound := item_resource(sound_item)
	if sound_item in now_playing:
		set_audio_attributes(sound)


func set_audio_attributes(sound):
	audio.volume_db = linear_to_db(sound.attributes.get("volume", ImportSound.DEFAULT_VOLUME))
	audio.pitch_scale = sound.attributes.get("pitch", ImportSound.DEFAULT_PITCH)
	

func get_data():
	var sounds := []
	for sound_item in root.get_children():
		var sound := item_resource(sound_item)
		var sound_data := {
			"sound": sound.path,
			"loop": sound_item.is_checked(0)
		}
		sounds.append(sound_data)
		if sound_item in now_playing:
			sound_data["position"] = snappedf(audio.sound_position, 0.001)
	
	return {
		"muted": muted,
		"sounds": sounds,
	}


func get_sounds_playing_data() -> Array:
	var playing := []
	for sound_item: TreeItem in now_playing:
		playing.append({"sound": sound_item.get_index(), "at": audio.sound_position})
	return playing


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
	if not FileAccess.file_exists(sound.abspath):
		Utils.temp_tooltip("This file no longer exists")
		return
		
	if is_playing:
		sound_item.set_button_color(1, 0, Color.GREEN)
		set_audio_attributes(sound)
		if sound_item not in now_playing:
			now_playing.append(sound_item)
			audio.file_path = sound.abspath
			audio.play(from_position)
	else:
		sound_item.set_button_color(1, 0, Color.DARK_GRAY)
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
		item_selected.free()


func _on_mute_button_pressed() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Jukebox"), muted)
	if mute_button.button_pressed:
		Game.server.rpcs.change_theme_volume.rpc(0)
	else:
		Game.server.rpcs.change_theme_volume.rpc(db_to_linear(audio.volume_db))


func _on_stop_button_pressed() -> void:
	for sound_item in now_playing:
		if is_instance_valid(sound_item):
			_set_playing(sound_item, false)
	Game.server.rpcs.play_theme_song.rpc("")
	Debug.print_info_message("Song \"%s\" stopped")
	

func _on_import_button_pressed():
	var resources_tab := Game.ui.tab_resources
	var resource: CampaignResource = resources_tab.resource_selected
	if not resource or resource.resource_type != CampaignResource.Type.SOUND:
		resources_tab.visible = true
		Utils.temp_tooltip("Select a Sound", 1)
		return
	
	var sound_item := add_sound(resource)
	sound_item.select(1)
	Game.server.rpcs.load_theme_song.rpc(resource.path)
	Debug.print_info_message("Sound added \"%s\"" % resource.path)


func _on_clear_button_pressed():
	if not item_selected: return
	
	_set_playing(item_selected, false)
	item_selected.free()
	Debug.print_info_message("Song \"%s\" removed")


func _on_items_moved(items: Array[TreeItem], index: int):
	if not items:
		return
		
	var paths: Array[String] = []
	for item: TreeItem in items:
		var sound := item_resource(item)
		paths.append(sound.path)
	
	#update_campaign()
	Debug.print_info_message("Songs %s moved to index %s" % [paths, index])
	

func reset():
	tree.clear()
	root = tree.create_item()
