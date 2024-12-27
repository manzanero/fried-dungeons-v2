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


@onready var steam_button: Button = %SteamButton
@onready var enet_button: Button = %EnetButton

@onready var steam_container: Control = %SteamContainer
@onready var steam_player_username_edit: LineEdit = %SteamPlayerUsernameEdit
@onready var steam_player_add_button: Button = %SteamPlayerAddButton
@onready var steam_filter_line_edit: LineEdit = %SteamFilterLineEdit
@onready var steam_refresh_button: Button = %SteamRefreshButton
@onready var steam_tree: DraggableTree = %SteamTree

@onready var enet_container: Control = %EnetContainer
@onready var enet_player_username_edit: LineEdit = %EnetPlayerUsernameEdit
@onready var enet_player_add_button: Button = %EnetPlayerAddButton
@onready var enet_filter_line_edit: LineEdit = %EnetFilterLineEdit
@onready var enet_refresh_button: Button = %EnetRefreshButton
@onready var enet_tree: DraggableTree = %EnetTree


var steam_root: TreeItem
var enet_root: TreeItem

var steam_items: Array[TreeItem] = []
var enet_items: Array[TreeItem] = []


func _ready() -> void:
	super._ready()
	
	if Game.server.is_steam_ready:
		steam_button.button_pressed = true
		steam_container.visible = true
		enet_container.visible = false
	else:
		enet_button.button_pressed = true
		steam_button.disabled = true
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
	)
	enet_button.pressed.connect(func (): 
		steam_container.visible = false
		enet_container.visible = true
	)
	
	## steam
	steam_player_add_button.pressed.connect(_on_player_add_button_pressed)
	steam_filter_line_edit.text_changed.connect(_on_steam_filter_changed.unbind(1))
	steam_refresh_button.pressed.connect(steam_refresh)
	steam_tree.item_activated.connect(_on_steam_item_activated)
	steam_tree.button_clicked.connect(_on_steam_item_button_clicked)

	## enet
	enet_player_add_button.pressed.connect(_on_player_add_button_pressed)
	enet_filter_line_edit.text_changed.connect(_on_enet_filter_changed.unbind(1))
	enet_refresh_button.pressed.connect(enet_refresh)
	enet_tree.item_activated.connect(_on_enet_item_activated)
	enet_tree.button_clicked.connect(_on_enet_item_button_clicked)
	

func _on_player_add_button_pressed():
	var new_player_username := enet_player_username_edit.text
	if steam_button.button_pressed:
		new_player_username = steam_player_username_edit.text
		
	if not new_player_username:
		Utils.temp_tooltip("Username cannot be empty")
		return
	
	var new_player_slug := Utils.slugify(new_player_username)
	var player_slugs := DirAccess.get_directories_at(Game.campaign.players_path)
	if new_player_slug in player_slugs:
		Utils.temp_tooltip("Username slug collides with another user")
		return
	
	var new_player_data := {
		"username": new_player_username,
		"password": _generate_pass(),
		"is_steam_player": steam_button.button_pressed,
		"color": Utils.color_to_html_color(Color.WHITE),
		"icon": "",
		"entities": [],
	}
	
	Game.campaign.set_player_data(new_player_slug, new_player_data)
	new_player.emit(new_player_slug)
	refresh()


func _generate_pass() -> String:
	return Utils.random_number_string(6)
	

func refresh():
	steam_refresh()
	enet_refresh()


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
		

func _on_steam_item_activated():
	var player_slug := steam_tree.get_selected().get_tooltip_text(0)
	player_activated.emit(player_slug)

func _on_enet_item_activated():
	var player_slug := enet_tree.get_selected().get_tooltip_text(0)
	player_activated.emit(player_slug)


func _on_steam_item_button_clicked(steam_item: TreeItem, _column: int, id: int, _mouse_button_index: int):
	match id:
		0: _on_remove_pressed(steam_item)


func _on_enet_item_button_clicked(enet_item: TreeItem, _column: int, id: int, _mouse_button_index: int):
	match id:
		0: _on_show_password_pressed(enet_item)
		1: _on_new_password_pressed(enet_item)
		2: _on_remove_pressed(enet_item)


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
	var player_path := Game.campaign.get_player_path(player_slug)
	Utils.remove_dirs(player_path)
	steam_items.erase(item)
	enet_items.erase(item)
	item.free()
	
	removed_player.emit(player_slug)
	

func steam_refresh():
	steam_tree.clear()
	steam_items.clear()
	steam_root = steam_tree.create_item()
	
	var player_slugs := DirAccess.get_directories_at(Game.campaign.players_path)
	
	for player_slug in player_slugs:
		var player_data := Game.campaign.get_player_data(player_slug)
		if not player_data.get("is_steam_player", false):
			continue
			
		var player_username: String = player_data.username
		
		var item := steam_root.create_child()
		
		item.set_text(0, player_username)
		item.set_tooltip_text(0, player_slug)
		item.set_metadata(0, player_data)
		
		item.add_button(0, REMOVE_ICON, 0)
		item.set_button_color(0, 0, Color.RED)
		
		steam_items.append(item)


func enet_refresh():
	enet_tree.clear()
	enet_items.clear()
	enet_root = enet_tree.create_item()
	
	var player_slugs := DirAccess.get_directories_at(Game.campaign.players_path)
	
	for player_slug in player_slugs:
		var player_data := Game.campaign.get_player_data(player_slug)
		if player_data.get("is_steam_player", false):
			continue
		
		var item := enet_root.create_child()
		
		item.set_text(0, player_data.username)
		item.set_tooltip_text(0, player_slug)
		item.set_metadata(0, player_data)
		
		item.set_text(1, "••••••")
		item.set_tooltip_text(1, " ")
		item.add_button(1, VISIBILITY_VISIBLE_ICON, 0)
		item.add_button(1, RELOAD_ICON, 1)
		item.set_metadata(1, false)
		
		item.add_button(1, REMOVE_ICON, 2)
		item.set_button_color(1, 2, Color.RED)
		
		enet_items.append(item)
