class_name TabPlayers
extends Control


const PLAYER_BUTTON := preload("res://ui/tabs/tab_players/player_button/player_button.tscn")
const ICON_DEFAULT: Texture2D = preload("res://user/defaults/icon/default.png")

var campaign_selected: Campaign : 
	set(value):
		campaign_selected = value
		scan(value)
		refresh_tree()


@onready var new_button: Button = %NewButton
@onready var scan_button: Button = %ScanButton
@onready var name_line_edit: LineEdit = %NameLineEdit

@onready var player_buttons: VBoxContainer = %PlayerButtons

@onready var add_entity: Button = %AddEntity
#@onready var remove_entity: Button = %RemoveEntity
@onready var username_line_edit: LineEdit = %UsernameLineEdit
@onready var username_button: Button = %UsernameButton
@onready var password_line_edit: LineEdit = %PasswordLineEdit
@onready var password_button: Button = %PasswordButton
@onready var folder_button: Button = %FolderButton
@onready var remove_button: Button = %RemoveButton


var cached_players := {}
var player_slug_selected: String
var player_selected := {} :
	get: return cached_players.get(player_slug_selected, player_selected) 


func _ready() -> void:
	new_button.pressed.connect(_on_new_button_pressed)
	scan_button.pressed.connect(_on_scan_button_pressed)
	name_line_edit.text_changed.connect(_on_filter_text_changed)
	
	add_entity.pressed.connect(_on_add_entity_pressed)
	username_button.pressed.connect(_on_username_button_pressed)
	password_button.pressed.connect(_on_password_button_pressed)
	
	folder_button.pressed.connect(_on_folder_button_pressed)
	remove_button.pressed.connect(_on_remove_button_pressed)


func _on_new_button_pressed():
	var campaign_path := campaign_selected.campaign_path
	var player_path := campaign_path.path_join("players/unnamed-player")
	var siblings := Utils.create_unique_folder(player_path)
	var player_unique_path := player_path if siblings == 1 else "%s-%s" % [player_path, siblings]
	var username := "Unnamed Player" if siblings == 1 else "Unnamed Player %s" % siblings
	Utils.dump_json(player_unique_path.path_join("player.json"), {
			"username": username,"password": "","entities": {}}, 2)
	
	scan(campaign_selected) 
	
	await refresh_tree()
	
	player_slug_selected = Utils.slugify(username)
	var player_button: PlayerButton = player_buttons.get_node(player_slug_selected)
	player_button.button.button_pressed = true


func _on_scan_button_pressed():
	scan(campaign_selected)
	refresh_tree()


func _on_filter_text_changed(_new_text: String):
	refresh_tree()


func scan(campaign: Campaign):
	cached_players.clear()
	if not campaign:
		return
	
	for players_slug in Utils.sort_strings_ended_with_number(campaign.players):
		cached_players[players_slug] = campaign.get_player_data(players_slug)
	
	player_slug_selected = ""


func save_player(players_slug):
	campaign_selected.set_player(players_slug, cached_players[players_slug])


func refresh_tree():
	var filter := name_line_edit.text
	
	for player_button: PlayerButton in player_buttons.get_children():
		player_button.queue_free()
		
	await get_tree().process_frame
	
	for player_slug in cached_players:
		var player_data: Dictionary = cached_players[player_slug]
		if filter and filter.to_lower() not in player_data.username.to_lower():
			continue
		
		var player_button: PlayerButton = PLAYER_BUTTON.instantiate().init(self, 
				player_slug, player_data.username, ICON_DEFAULT, player_data.get("entities", {}))
		player_button.name = player_slug


func _on_add_entity_pressed():
	var entity := Game.ui.selected_map.selected_level.element_selected; 
	if not is_instance_valid(entity) or entity is not Entity:
		return
		
	var player := player_selected
	if not player: 
		return
	
	var player_button: PlayerButton = player_buttons.get_node(player_slug_selected)
	if not is_instance_valid(player_button) or not player_button.button.button_pressed: 
		return
	
	player_button.add_player_entity(entity)
	var entity_data: Dictionary = player_button.player_entities_data[entity.id]
	player.entities[entity.id] = entity_data
	
	save_player(player_slug_selected)
	
	Game.server.rpcs.set_player_entity_control.rpc(player_slug_selected, entity.id, true, entity_data)
	
	Debug.print_info_message("Entity \"%s\" added to player \"%s\"" % [entity.id, player_slug_selected])


func _on_username_button_pressed():
	var player := player_selected; if not player: return
	var username: String = player.username
	var new_username := username_line_edit.text.strip_edges(); if new_username == "": return
	var new_player_slug := Utils.slugify(new_username); if new_player_slug in campaign_selected.players: return
	
	var player_button: PlayerButton = player_buttons.get_node(player_slug_selected)
	if not is_instance_valid(player_button) or not player_button.button.button_pressed: 
		return
		
	username_line_edit.text = ""
	player_button.name = new_player_slug
	player_button.slug = new_player_slug
	player_button.username = new_username
	var player_path := campaign_selected.players_path.path_join(player_slug_selected)
	var new_player_path := campaign_selected.players_path.path_join(new_player_slug)
	if Utils.rename(player_path, new_player_path):
		Debug.print_error_message("Player folder \"%s\" not renamed to \"%s\"" % [player_slug_selected, new_player_slug])
		return
	
	cached_players[new_player_slug] = player
	cached_players[new_player_slug].username = new_username
	cached_players.erase(player_slug_selected)
	save_player(new_player_slug)
	player_slug_selected = new_player_slug
	
	Debug.print_info_message("Player \"%s\" (%s) changed to \"%s\" (%s)" % [
			username, player_slug_selected, new_username, new_player_slug])


func _on_password_button_pressed():
	var player := player_selected; if not player: return
	var new_password := password_line_edit.text; if new_password == "": return
	
	var player_button: PlayerButton = player_buttons.get_node(player_slug_selected)
	if not is_instance_valid(player_button) or not player_button.button.button_pressed: 
		return
	
	password_line_edit.text = ""
	player.password = new_password
	save_player(player_slug_selected)
	
	Debug.print_info_message("Player \"%s\" (%s) changed password" % [player.username, player_slug_selected])


func _on_folder_button_pressed() -> void:
	if not player_slug_selected:
		return
	
	var path := campaign_selected.players_path.path_join(player_slug_selected)
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(path))
	

func _on_remove_button_pressed():
	if not player_slug_selected:
		return
		
	var path := campaign_selected.players_path.path_join(player_slug_selected)
	Utils.remove_dirs(path)
	
	scan(campaign_selected)
	refresh_tree()
