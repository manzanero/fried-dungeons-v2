class_name MainMenu
extends Control


signal host_campaign_pressed(campaign_data: Dictionary)
signal join_server_pressed(host: String, username: String, password: String)


const CAMPAIGN_BUTTON = preload("res://ui/main_menu/campaign_button/campaign_button.tscn")
const SERVER_BUTTON = preload("res://ui/main_menu/server_button/server_button.tscn")

@export var campaign_buttons: Control
@export var server_buttons: Control

var campaign_buttons_group: ButtonGroup
var server_buttons_group: ButtonGroup
var server_button_pressed: ServerButton


@onready var exit_main_menu_button: Button = %ExitMainMenuButton

# host
@onready var new_button: Button = %NewButton
@onready var scan_button: Button = %ScanButton
@onready var title_line_edit: LineEdit = %TitleLineEdit

@onready var host_button: Button = %HostButton
@onready var folder_button: Button = %FolderButton
@onready var delete_button: Button = %DeleteButton

# new campaign
@onready var new_campaign_container: CenterContainer = %NewCampaignContainer
@onready var new_campaign_name_line_edit: LineEdit = %NewCampaignNameLineEdit
@onready var new_campaign_add_button: Button = %NewCampaignAddButton
@onready var existing_campaign_error: Label = %ExistingCampaignError
@onready var exit_new_campaign_button: Button = %ExitNewCampaignButton

# join
@onready var host_line_edit: LineEdit = %HostLineEdit
@onready var username_line_edit: LineEdit = %UsernameLineEdit
@onready var password_line_edit: LineEdit = %PasswordLineEdit
@onready var add_button: Button = %AddButton

@onready var join_server_button: Button = %JoinServerButton
@onready var folder_server_button: Button = %FolderServerButton
@onready var remove_server_button: Button = %RemoveServerButton


func _ready() -> void:
	new_campaign_container.visible = false
	existing_campaign_error.visible = false
	
	scan_campaigns()
	scan_servers()
	
	exit_main_menu_button.pressed.connect(func (): 
		if Game.ui.ide.visible:
			visible = false
		else:
			get_tree().quit()
	)
	
	# host
	new_button.pressed.connect(_on_new_button_pressed)
	scan_button.pressed.connect(scan_campaigns)
	scan_button.pressed.connect(scan_servers)
	title_line_edit.text_changed.connect(_on_title_line_edit_text_changed)
	host_button.pressed.connect(_on_host_button_pressed)
	folder_button.pressed.connect(_on_folder_button_pressed)
	delete_button.pressed.connect(_on_delete_campaign_button_pressed)

	# new campaign
	exit_new_campaign_button.pressed.connect(func (): new_campaign_container.visible = false)
	new_campaign_add_button.pressed.connect(_on_new_campaign_add_button_pressed)
	
	# join
	join_server_button.pressed.connect(_on_join_server_button_pressed)
	folder_server_button.pressed.connect(_on_folder_server_button_pressed)
	remove_server_button.pressed.connect(_on_remove_server_button_pressed)

	# new server
	add_button.pressed.connect(_on_new_server_add_button_pressed)


func scan_campaigns():
	Utils.queue_free_children(campaign_buttons)
	
	var campaigns_path := "user://campaigns"
	Utils.make_dirs(campaigns_path)
	var campaign_slugs := DirAccess.get_directories_at(campaigns_path)
	Debug.print_info_message("Campaigns: %s" % str(campaign_slugs))

	var filter := title_line_edit.text
	for campaign_slug in campaign_slugs:
		var campaign_button: CampaignButton = CAMPAIGN_BUTTON.instantiate().init(campaign_buttons, campaign_slug)
		campaign_button.visible = not filter or filter in campaign_button.campaign_name
		campaign_buttons_group = campaign_button.button.button_group


func scan_servers():
	Utils.queue_free_children(server_buttons)
	
	var servers_path := "user://servers"
	Utils.make_dirs(servers_path)
	var server_slugs := DirAccess.get_directories_at(servers_path)
	Debug.print_info_message("Servers: %s" % str(server_slugs))
	
	for server_slug in server_slugs:
		var server_path := servers_path.path_join(server_slug)
		var server_data := Utils.load_json(server_path.path_join("server.json"))
		
		var server_icon_path := server_path.path_join("icon.png")
		var icon := Utils.png_to_texture(server_icon_path)
		if not icon:
			icon = load("res://user/defaults/icon/default.png") as Texture2D
		
		var players_path := servers_path.path_join(server_slug).path_join("players")
		Utils.make_dirs(players_path)
		var player_slugs := DirAccess.get_directories_at(players_path)
		Debug.print_info_message("Server \"%s\" players: %s" % [server_slug, str(player_slugs)])
		
		for player_slug in player_slugs:
			var player_path := players_path.path_join(player_slug)
			var player_data := Utils.load_json(player_path.path_join("player.json"))
			
			var server_button: ServerButton = SERVER_BUTTON.instantiate().init(server_buttons, 
					server_slug, server_data, player_data, icon)
				
			server_buttons_group = server_button.button.button_group


func _on_new_button_pressed():
	new_campaign_container.visible = true
	existing_campaign_error.visible = false
	new_campaign_name_line_edit.text = ""


func _on_new_campaign_add_button_pressed():
	var campaign_name := new_campaign_name_line_edit.text
	var slug := Utils.slugify(campaign_name)
	var campaign_path := "user://campaigns".path_join(slug)
	
	if DirAccess.dir_exists_absolute(campaign_path):
		existing_campaign_error.visible = true
		return
		
	Utils.make_dirs(campaign_path)
	Utils.dump_json(campaign_path.path_join("campaign.json"), {
		"label": campaign_name,
	})
	Utils.make_dirs(campaign_path.path_join("maps/untitled-map"))
	Utils.dump_json(campaign_path.path_join("maps/untitled-map/map.json"), {
		"label": "Untitled Map"
	})
	Utils.make_dirs(campaign_path.path_join("players"))
	Utils.make_dirs(campaign_path.path_join("resources"))
	
	new_campaign_container.visible = false
	scan_campaigns()


func _on_title_line_edit_text_changed(filter: String):
	for campaign_button in campaign_buttons.get_children():
		campaign_button.visible = not filter or filter in campaign_button.campaign_name


func _on_host_button_pressed():
	var campaing_pressed := campaign_buttons_group.get_pressed_button()
	if not campaing_pressed:
		return
		
	if Game.server.host_multiplayer():
		return
	
	campaing_pressed.button_pressed = false
	
	var campaign_slug: String = campaing_pressed.get_parent().slug
	var campaign_path := "user://campaigns".path_join(campaign_slug).path_join("campaign.json")
	var campaign_data := Utils.load_json(campaign_path)
	
	host_campaign_pressed.emit(campaign_data)


func _on_folder_button_pressed():
	var campaing_pressed := campaign_buttons_group.get_pressed_button()
	if campaing_pressed:
		var campaign_path := "user://campaigns".path_join(campaing_pressed.get_parent().slug)
		Utils.open_in_file_manager(campaign_path)


func _on_delete_campaign_button_pressed():
	var campaing_pressed := campaign_buttons_group.get_pressed_button()
	if campaing_pressed:
		var path := "user://campaigns/%s" % campaing_pressed.get_parent().slug
		Utils.remove_dirs(path)
	
	scan_campaigns()


func _on_join_server_button_pressed():
	var server_pressed := server_buttons_group.get_pressed_button()
	if not server_pressed:
		return
	
	Utils.reset_button_group(server_buttons_group)
	
	server_button_pressed = server_pressed.get_parent()
	var server_data := server_button_pressed.server_data
	var player_data := server_button_pressed.player_data
	join_server_pressed.emit(server_data.host, player_data.username, player_data.password)


func _on_folder_server_button_pressed():
	var server_pressed := server_buttons_group.get_pressed_button()
	if server_pressed:
		Utils.open_in_file_manager("user://servers/%s" % server_pressed.get_parent().slug)


func _on_remove_server_button_pressed():
	var server_pressed := server_buttons_group.get_pressed_button()
	if not server_pressed:
		return
	
	server_button_pressed = server_pressed.get_parent()
	var server_slug := server_button_pressed.slug
	var player_data := server_button_pressed.player_data
	var player_slug := Utils.slugify(player_data.username)
	var server_path := "user://servers".path_join(server_slug)
	var players_path := server_path.path_join("players")
	var player_path := players_path.path_join(player_slug)
	Utils.remove_dirs(player_path)
	
	if not DirAccess.get_directories_at(players_path):
		Utils.remove_dirs(server_path)

	scan_servers()


func _on_new_server_add_button_pressed():
	var host := host_line_edit.text
	var username := username_line_edit.text
	var password := password_line_edit.text
	join_server_pressed.emit(host, username, password)
