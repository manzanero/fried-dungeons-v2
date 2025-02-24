class_name CampaignPlayersWindow
extends FriedWindow


signal new_player(player_slug: String)
signal player_edited(player_slug: String)
signal player_activated(player_slug: String)
signal removed_player(player_slug: String)


const VISIBILITY_VISIBLE_ICON = preload("res://resources/icons/visibility_visible_icon.png")
const VISIBILITY_HIDDEN_ICON = preload("res://resources/icons/visibility_hidden_icon.png")
const RELOAD_ICON = preload("res://resources/icons/reload_icon.png")
const REMOVE_ICON := preload("res://resources/icons/cross_icon.png")
const POPUP_PANEL = preload("res://resources/themes/main/popup_panel.tres")
const FRIED_CONVEX_PANEL = preload("res://ui/fried_convex_panel/fried_convex_panel.tscn")
const SQUARE_ICON = preload("res://resources/icons/square_icon.png")
const TRASH_ICON = preload("res://resources/icons/trash_icon.png")

@onready var steam_button: Button = %SteamButton
@onready var enet_button: Button = %EnetButton

@onready var steam_container: Control = %SteamContainer
@onready var steam_color_edit: ColorEdit = %SteamColorEdit
@onready var steam_player_username_edit: LineEdit = %SteamPlayerUsernameEdit
@onready var steam_player_steam_user_edit: LineEdit = %SteamPlayerSteamUserEdit
@onready var steam_player_add_button: Button = %SteamPlayerAddButton
@onready var steam_folders_button: Button = %SteamFoldersButton
@onready var steam_filter_line_edit: LineEdit = %SteamFilterLineEdit
@onready var steam_refresh_button: Button = %SteamRefreshButton
@onready var steam_tree: DraggableTree = %SteamTree
@onready var steam_edit_color_edit: ColorEdit = %SteamEditColorEdit
@onready var steam_edit_player_username_edit: LineEdit = %SteamEditPlayerUsernameEdit
@onready var steam_edit_player_steam_user_edit: LineEdit = %SteamEditPlayerSteamUserEdit
@onready var steam_edit_player_button: Button = %SteamEditPlayerAddButton

@onready var enet_container: Control = %EnetContainer
@onready var enet_color_edit: ColorEdit = %EnetColorEdit
@onready var enet_player_username_edit: LineEdit = %EnetPlayerUsernameEdit
@onready var enet_player_add_button: Button = %EnetPlayerAddButton
@onready var enet_folders_button: Button = %EnetFoldersButton
@onready var enet_filter_line_edit: LineEdit = %EnetFilterLineEdit
@onready var enet_refresh_button: Button = %EnetRefreshButton
@onready var enet_tree: DraggableTree = %EnetTree
@onready var enet_edit_color_edit: ColorEdit = %EnetEditColorEdit
@onready var enet_edit_player_username_edit: LineEdit = %EnetEditPlayerUsernameEdit
@onready var enet_edit_player_button: Button = %EnetEditPlayerAddButton


var steam_root: TreeItem
var enet_root: TreeItem

var steam_items: Array[TreeItem] = []
var enet_items: Array[TreeItem] = []


# shortcut to open and edit
func edit_player_by_username(username: String) -> void:
	var items := steam_items if steam_button.button_pressed else enet_items
	for item in items:
		if username == item.get_text(0):
			item.select(0)


func _ready() -> void:
	super._ready()
	
	enet_button.button_pressed = true
	steam_container.visible = false
	enet_container.visible = true
	
	visibility_changed.connect(func ():
		if Game.campaign and visible:
			if Game.server.is_steam_game:
				steam_button.button_pressed = true
				steam_button.pressed.emit()
			else:
				enet_button.button_pressed = true
				enet_button.pressed.emit()
			refresh()
	)

	steam_button.pressed.connect(func (): 
		steam_container.visible = true
		enet_container.visible = false
		_clear()
	)
	enet_button.pressed.connect(func (): 
		steam_container.visible = false
		enet_container.visible = true
		_clear()
	)
	
	## steam
	steam_player_add_button.pressed.connect(_on_player_add_button_pressed.bind(true))
	steam_edit_player_button.pressed.connect(_on_player_edit_button_pressed.bind(true))
	steam_folders_button.pressed.connect(_on_folders_button_pressed)
	steam_filter_line_edit.text_changed.connect(_on_steam_filter_changed.unbind(1))
	steam_refresh_button.pressed.connect(_on_steam_refresh_button_pressed)
	steam_tree.item_activated.connect(_on_steam_item_activated)
	steam_tree.item_selected.connect(_on_steam_item_selected)
	steam_tree.button_clicked.connect(_on_steam_item_button_clicked)
	steam_tree.empty_clicked.connect(steam_tree.deselect_all.unbind(2))
	
	## enet
	enet_player_add_button.pressed.connect(_on_player_add_button_pressed.bind(false))
	enet_edit_player_button.pressed.connect(_on_player_edit_button_pressed.bind(false))
	enet_folders_button.pressed.connect(_on_folders_button_pressed)
	enet_filter_line_edit.text_changed.connect(_on_enet_filter_changed.unbind(1))
	enet_refresh_button.pressed.connect(_on_enet_refresh_button_pressed)
	enet_tree.item_activated.connect(_on_enet_item_activated)
	enet_tree.item_selected.connect(_on_enet_item_selected)
	enet_tree.button_clicked.connect(_on_enet_item_button_clicked)
	enet_tree.item_mouse_selected.connect(_on_enet_item_mouse_selected)
	enet_tree.empty_clicked.connect(enet_tree.deselect_all.unbind(2))


func _on_folders_button_pressed():
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(Game.campaign.players_path))


func _on_player_add_button_pressed(steam_player := false):
	var new_player_username := enet_player_username_edit.text
	var new_player_color := enet_color_edit.color
	var new_player_steam_user := ""
	if steam_player:
		new_player_username = steam_player_username_edit.text
		new_player_color = steam_color_edit.color
		new_player_steam_user = steam_player_steam_user_edit.text
		
	if not new_player_username:
		Utils.temp_error_tooltip("Username cannot be empty")
		return
	if steam_player and not new_player_steam_user:
		Utils.temp_error_tooltip("Steam user cannot be empty")
		return
	
	var new_player_slug := Utils.slugify(new_player_username)
	var new_player_data := Game.campaign.get_player_data(new_player_slug, true)
	if new_player_data and new_player_username != new_player_data.username:
		Utils.temp_error_tooltip("Player's name collides with another player")
		return
		
	new_player_data["username"] = new_player_username
	new_player_data["color"] = Utils.color_to_html_color(new_player_color)
	if not new_player_data.has("password"):
		new_player_data["password"] = _generate_pass()
	if steam_player:
		new_player_data["steam_user"] = new_player_steam_user
	
	Game.campaign.set_player_data(new_player_slug, new_player_data)
	new_player.emit(new_player_slug)
	refresh()
	Game.ui.tab_players.reset()
	
	Utils.temp_info_tooltip("Player created")
	
	
func _on_player_edit_button_pressed(steam_player := false):
	var selected_item := enet_tree.get_selected()
	if steam_player:
		selected_item = steam_tree.get_selected()
	if not selected_item:
		Utils.temp_error_tooltip("User not selected")
		return
	
	var new_player_username := enet_edit_player_username_edit.text
	var new_player_color := enet_edit_color_edit.color
	var new_player_steam_user := ""
	if steam_player:
		new_player_username = steam_edit_player_username_edit.text
		new_player_color = steam_edit_color_edit.color
		new_player_steam_user = steam_edit_player_steam_user_edit.text
		
	if not new_player_username:
		Utils.temp_error_tooltip("Username cannot be empty")
		return
	if steam_player and not new_player_steam_user:
		Utils.temp_error_tooltip("Steam user cannot be empty")
		return
	
	var new_player_slug := Utils.slugify(new_player_username)
	var new_player_data := Game.campaign.get_player_data(new_player_slug, true)
	
	var player_slug: String = selected_item.get_tooltip_text(0)
	new_player_data = Game.campaign.get_player_data(player_slug)
	
	new_player_data["username"] = new_player_username
	new_player_data["color"] = Utils.color_to_html_color(new_player_color)
	if not new_player_data.has("password"):
		new_player_data["password"] = _generate_pass()
	if steam_player:
		new_player_data["steam_user"] = new_player_steam_user
	
	var player_path := Game.campaign.get_player_path(player_slug)
	var new_player_path := Game.campaign.get_player_path(new_player_slug)
	if Utils.rename(player_path, new_player_path):
		Utils.temp_error_tooltip("Cannot rename user")
		return
		
	Game.campaign.set_player_data(new_player_slug, new_player_data)
	#new_player.emit(new_player_slug)
	refresh()
	Game.ui.tab_players.reset()
	
	Game.server.rpcs.change_player.rpc(player_slug, new_player_username, new_player_color)
	
	Utils.temp_info_tooltip("Player updated")


func _generate_pass() -> String:
	return Utils.random_number_string(6)
	

func refresh():
	steam_refresh()
	enet_refresh()
	_clear()

func _clear():
	if steam_button.button_pressed:
		steam_filter_line_edit.grab_focus()
	else:
		enet_filter_line_edit.grab_focus()
	enet_player_username_edit.clear()
	enet_color_edit.color = Color.WHITE
	steam_player_username_edit.clear()
	steam_color_edit.color = Color.WHITE
	steam_player_steam_user_edit.clear()
	enet_edit_player_username_edit.clear()
	enet_edit_color_edit.color = Color.WHITE
	steam_edit_player_username_edit.clear()
	steam_edit_color_edit.color = Color.WHITE
	steam_edit_player_steam_user_edit.clear()
	enet_tree.deselect_all()
	steam_tree.deselect_all()


func _on_steam_filter_changed():
	var filter := Utils.slugify(steam_filter_line_edit.text.to_lower())
	for item in steam_items:
		var data: Dictionary = item.get_metadata(0)
		if filter and filter not in Utils.slugify(data.username.to_lower()):
			item.visible = false
		else:
			item.visible = true

func _on_enet_filter_changed():
	var filter := Utils.slugify(enet_filter_line_edit.text.to_lower())
	for item in enet_items:
		var data: Dictionary = item.get_metadata(0)
		if filter and filter not in Utils.slugify(data.username.to_lower()):
			item.visible = false
		else:
			item.visible = true
		

func _on_steam_item_selected():
	var player_data = steam_tree.get_selected().get_metadata(0)
	steam_edit_player_username_edit.text = player_data.username
	steam_edit_color_edit.color = Utils.html_color_to_color(player_data.color)
	steam_edit_player_steam_user_edit.text = player_data.steam_user

func _on_enet_item_selected():
	var player_data = enet_tree.get_selected().get_metadata(0)
	enet_edit_player_username_edit.text = player_data.username
	enet_edit_color_edit.color = Utils.html_color_to_color(player_data.color)
	
	
func _on_steam_item_activated():
	var player_slug := steam_tree.get_selected().get_tooltip_text(0)
	player_activated.emit(player_slug)

func _on_enet_item_activated():
	var player_slug := enet_tree.get_selected().get_tooltip_text(0)
	player_activated.emit(player_slug)
	
	var player_data: Dictionary = enet_tree.get_selected().get_metadata(0)
	DisplayServer.clipboard_set(player_data.password)
	Utils.temp_info_tooltip("Copied!")


func _on_steam_item_button_clicked(steam_item: TreeItem, _column: int, id: int, _mouse_button_index: int):
	match id:
		0: _on_remove_pressed(steam_item)


func _on_enet_item_button_clicked(enet_item: TreeItem, _column: int, id: int, _mouse_button_index: int):
	match id:
		0: _on_show_password_pressed(enet_item)
		1: _on_new_password_pressed(enet_item)
		2: _on_remove_pressed(enet_item)


func _on_enet_item_mouse_selected(_mouse_position: Vector2, mouse_button_index: int):
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		DisplayServer.clipboard_set(enet_tree.get_selected().get_metadata(0).password)
		Utils.temp_info_tooltip("Copied!")
	

func _on_show_password_pressed(item: TreeItem):
	var player_data: Dictionary = item.get_metadata(0)
	var password_visible: bool = item.get_metadata(1)
	if password_visible:
		item.set_text(1, "••••••")
		item.set_metadata(1, false)
		item.set_button(1, 0, VISIBILITY_VISIBLE_ICON)
	else:
		item.set_text(1, player_data.password)
		item.set_metadata(1, true)
		item.set_button(1, 0, VISIBILITY_HIDDEN_ICON)


func _on_new_password_pressed(item: TreeItem):
	var player_slug := item.get_tooltip_text(0)
	var player_data: Dictionary = item.get_metadata(0)
	player_data.password = _generate_pass()
	item.set_text(1, player_data.password)
	item.set_metadata(1, true)
	item.set_button(1, 0, VISIBILITY_HIDDEN_ICON)
	
	Game.campaign.set_player_data(player_slug, player_data)
	player_edited.emit(player_slug)


func _on_remove_pressed(item: TreeItem):
	var player_slug := item.get_tooltip_text(0)
	var player_data := Game.campaign.get_player_data(player_slug)
	if steam_button.button_pressed:
		player_data.erase("steam_user")
		Game.campaign.set_player_data(player_slug, player_data)
	else:
		var player_path := Game.campaign.get_player_path(player_slug)
		if Utils.remove_dirs(player_path):
			Utils.temp_error_tooltip("Error removing player")
		
	refresh()
	Game.ui.tab_players.reset()
		
	removed_player.emit(player_slug)
	
	
func _on_steam_refresh_button_pressed():
	steam_refresh()
	Utils.temp_info_tooltip("Reloaded")
	
	
func _on_enet_refresh_button_pressed():
	enet_refresh()
	Utils.temp_info_tooltip("Reloaded")


func steam_refresh():
	steam_tree.clear()
	steam_items.clear()
	steam_root = steam_tree.create_item()
	
	var player_slugs := DirAccess.get_directories_at(Game.campaign.players_path)
	
	for player_slug in player_slugs:
		var player_data := Game.campaign.get_player_data(player_slug)
		var player_steam_user: String = player_data.get("steam_user", "")
		if not player_steam_user:
			continue
		
		var item := steam_root.create_child()
		
		item.set_icon(0, SQUARE_ICON)
		item.set_icon_modulate(0, Utils.html_color_to_color(player_data.color))
		item.set_text(0, player_data.username)
		item.set_text(1, player_steam_user)
		item.set_tooltip_text(0, player_slug)
		item.set_tooltip_text(1, player_slug)
		item.set_metadata(0, player_data)
		
		item.add_button(1, REMOVE_ICON, 0)
		item.set_button_color(1, 0, Color.RED)
		
		steam_items.append(item)
	
	_on_steam_filter_changed()


func enet_refresh():
	enet_tree.clear()
	enet_items.clear()
	enet_root = enet_tree.create_item()
	
	var player_slugs := DirAccess.get_directories_at(Game.campaign.players_path)
	
	for player_slug in player_slugs:
		var player_data := Game.campaign.get_player_data(player_slug)
		
		var item := enet_root.create_child()
		
		item.set_icon(0, SQUARE_ICON)
		item.set_icon_modulate(0, Utils.html_color_to_color(player_data.color))
		item.set_text(0, player_data.username)
		item.set_tooltip_text(0, player_slug)
		item.set_metadata(0, player_data)
		
		item.set_text(1, "••••••")
		item.set_tooltip_text(1, " ")
		item.add_button(1, VISIBILITY_VISIBLE_ICON, 0)
		item.add_button(1, RELOAD_ICON, 1)
		item.set_metadata(1, false)
		
		item.add_button(1, TRASH_ICON, 2)
		item.set_button_color(1, 2, Color.RED)
		
		enet_items.append(item)
	
	_on_enet_filter_changed()
