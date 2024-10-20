class_name TabJukebox
extends Control

const SOUND_ICON := preload("res://resources/icons/sound_icon.png")
const STOP_ICON := preload("res://resources/icons/stop_icon.png")
const PLAY_ICON := preload("res://resources/icons/play_icon.png")
const LOOP_ICON := preload("res://resources/icons/reload_icon.png")

var root: TreeItem
var now_playing := []

var item_selected: TreeItem :
	get: return tree.get_selected() if is_instance_valid(tree.get_selected()) else null

var sound_selected: CampaignResource :
	get: return item_resource(item_selected) if item_selected else null
	
func item_resource(item: TreeItem) -> CampaignResource:
	return item.get_metadata(1)


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
		
	var sound_item: TreeItem = now_playing[0]
	if sound_item.is_checked(0):
		audio.play()
		Game.server.rpcs.play_theme_song.rpc(item_resource(sound_item).path)
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
	
	#update_campaign()
	return sound_item


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
		"sounds": sounds,
	}


func get_sounds_playing_data() -> Array:
	var playing := []
	for sound_item: TreeItem in now_playing:
		playing.append({"sound": sound_item.get_index(), "at": audio.sound_position})
	return playing


func _on_item_activated():
	if not sound_selected: return
	
	var resources_tab := Game.ui.tab_instancer
	resources_tab.visible = true
	var resource_item := resources_tab.resource_items.get(sound_selected.path) as TreeItem
	resource_item.uncollapse_tree()
	resource_item.select(0)
	var resource_tree := resource_item.get_tree()
	resource_tree.item_activated.emit()
	

func _set_playing(sound_item: TreeItem, is_playing: bool, from_position := 0.0) -> void:
	if is_playing:
		sound_item.set_button_color(1, 0, Color.GREEN)
		if sound_item not in now_playing:
			now_playing.append(sound_item)
			audio.file_path = item_resource(sound_item).abspath
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
	Game.server.rpcs.play_theme_song.rpc(item_resource(item).path)


func _on_mute_button_pressed() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Jukebox"), mute_button.button_pressed)
	Game.server.rpcs.change_theme_volume.rpc(0 if mute_button.button_pressed else 1)


func _on_stop_button_pressed() -> void:
	for sound_item in now_playing:
		_set_playing(sound_item, false)
	Game.server.rpcs.play_theme_song.rpc("")
	Debug.print_info_message("Song \"%s\" stopped")
	

func _on_import_button_pressed():
	var resources_tab := Game.ui.tab_instancer
	var resource: CampaignResource = resources_tab.resource_selected
	if not resource or resource.type != CampaignResource.Type.SOUND:
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
	#update_campaign()
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
