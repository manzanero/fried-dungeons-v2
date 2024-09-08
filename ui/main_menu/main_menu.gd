class_name MainMenu
extends Control


signal host_campaign_pressed(campaign: Campaign)
signal join_server_pressed(server: Dictionary)


const CAMPAIGN_BUTTON = preload("res://ui/main_menu/campaign_button/campaign_button.tscn")
const SERVER_BUTTON = preload("res://ui/main_menu/server_button/server_button.tscn")

@export var campaign_buttons: Control
@export var server_buttons: Control

var campaign_buttons_group: ButtonGroup
var server_buttons_group: ButtonGroup


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
	var campaigns_path := "user://campaigns"
	
	if not DirAccess.dir_exists_absolute(campaigns_path):
		DirAccess.make_dir_recursive_absolute(campaigns_path)
	var campaigns := DirAccess.get_directories_at(campaigns_path)
	
	Debug.print_info_message("Campaigns: %s" % str(campaigns))
	
	for campaign_button in campaign_buttons.get_children():
		campaign_button.queue_free()
	
	var filter := title_line_edit.text
	for campaign in campaigns:
		var campaign_button: CampaignButton = CAMPAIGN_BUTTON.instantiate().init(campaign_buttons, campaign)
		campaign_button.visible = not filter or filter in campaign_button.campaign_name
		campaign_buttons_group = campaign_button.button.button_group


func scan_servers():
	var servers_path := "user://servers"
	
	if not DirAccess.dir_exists_absolute(servers_path):
		DirAccess.make_dir_recursive_absolute(servers_path)
	var server_slugs := DirAccess.get_directories_at(servers_path)
	
	Debug.print_info_message("Servers: %s" % str(server_slugs))
	
	for server_button in server_buttons.get_children():
		server_button.queue_free()
	
	for server_slug in server_slugs:
		var server_path := servers_path.path_join(server_slug)
		var server_data := Utils.load_json(server_path.path_join("server.json"))
		var server_icon_path := server_path.path_join("icon.png")
		var icon: Texture2D
		if FileAccess.file_exists(server_icon_path):
			icon = Utils.png_to_texture(server_icon_path)
		else:
			icon = load("res://user/defaults/icon/default.png") as Texture2D
		var server_button: ServerButton = SERVER_BUTTON.instantiate().init(server_buttons, 
				server_slug, server_data.label, server_data.host, server_data.username, icon)
				
		server_buttons_group = server_button.button.button_group


func _on_new_button_pressed():
	new_campaign_container.visible = true
	existing_campaign_error.visible = false
	new_campaign_name_line_edit.text = ""
	

func _on_new_campaign_add_button_pressed():
	var campaign_name := new_campaign_name_line_edit.text
	var slug := Utils.slugify(campaign_name)
	var campaign_path := "user://campaigns/%s" % slug
	
	if DirAccess.dir_exists_absolute(campaign_path):
		existing_campaign_error.visible = true
		return
		
	Utils.make_dirs(campaign_path)
	Utils.dump_json(campaign_path.path_join("campaign.json"), {
		"label": campaign_name
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
	
	campaing_pressed.button_pressed = false
		
	var path := "user://campaigns/%s" % campaing_pressed.get_parent().slug
	var global_path := ProjectSettings.globalize_path(path)
	var campaign_data := Utils.load_json(global_path + "/campaign.json")
	
	var campaign = Campaign.new().init(campaign_data.label)
	host_campaign_pressed.emit(campaign)
	
	Game.player_name = "Master"
	Game.player_is_master = true
	Game.server.host_multiplayer()
	

func _on_folder_button_pressed():
	var campaing_pressed := campaign_buttons_group.get_pressed_button()
	if campaing_pressed:
		var path := "user://campaigns/%s" % campaing_pressed.get_parent().slug
		var global_path := ProjectSettings.globalize_path(path)
		OS.shell_show_in_file_manager(global_path)
		
		
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
	
	server_pressed.button_pressed = false
	
	var server_slug: String = server_pressed.get_parent().slug
	var username: String = server_pressed.get_parent().username
	var path := "user://servers".path_join(server_slug)
	var global_path := ProjectSettings.globalize_path(path)
	var server_data := Utils.load_json(global_path.path_join("/server.json"))
	
	join_server_pressed.emit(server_data)
	
	Game.player_name = username
	Game.player_is_master = false
	Game.server.join_multiplayer(server_data.host)
		

func _on_folder_server_button_pressed():
	var server_pressed := server_buttons_group.get_pressed_button()
	if server_pressed:
		var path := "user://servers/%s" % server_pressed.get_parent().slug
		var global_path := ProjectSettings.globalize_path(path)
		OS.shell_show_in_file_manager(global_path)
		
		
func _on_remove_server_button_pressed():
	var server_pressed := server_buttons_group.get_pressed_button()
	if server_pressed:
		var path := "user://servers/%s" % server_pressed.get_parent().slug
		Utils.remove_dirs(path)
	
	scan_servers()
		
		
func _on_new_server_add_button_pressed():
	var server_host := host_line_edit.text
	var server_user := username_line_edit.text
	var server_pass := password_line_edit.text
	
	#ask server
	var slug := "new-campaign"
	var server_name := "New Campaign"
	var icon: Texture2D = null

	var server_path := "user://servers/%s" % slug
	Utils.make_dirs(server_path.path_join("maps"))
	Utils.make_dirs(server_path.path_join("resources"))
	Utils.dump_json(server_path.path_join("server.json"), {
		"label": server_name,
		"host": server_host,
		"username": server_user,
		"password": server_pass,
	})
	
	scan_servers()


	
