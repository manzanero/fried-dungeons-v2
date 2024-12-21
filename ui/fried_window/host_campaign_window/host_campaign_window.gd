class_name HostCampaignWindow
extends FriedWindow

signal saved_campaign_hosted(campaign_slug: String, campaign_data: Dictionary, steam: bool)

const PLAY_ICON := preload("res://resources/icons/play_icon.png")
const FOLDER_ICON := preload("res://resources/icons/directory_icon.png")
const REMOVE_ICON := preload("res://resources/icons/cross_icon.png")


@onready var steam_button: Button = %SteamButton
@onready var enet_button: Button = %EnetButton

@onready var new_button: Button = %NewButton
@onready var filter_line_edit: LineEdit = %FilterLineEdit
@onready var refresh_button: Button = %RefreshButton
@onready var tree: DraggableTree = %Tree


var campaigns_path := "user://campaigns"
var root: TreeItem

var items: Array[TreeItem] = []

var item_selected: TreeItem :
	get: return tree.get_selected()


func _ready() -> void:
	super._ready()
	
	if Game.server.is_steam_ready:
		steam_button.button_pressed = true
	else:
		enet_button.button_pressed = true
		steam_button.disabled = true

	Utils.make_dirs(campaigns_path)
	filter_line_edit.text_changed.connect(_on_filter_changed.unbind(1))
	new_button.pressed.connect(func ():
		visible = false
		Game.ui.new_campaign_window.visible = true
	)
	refresh_button.pressed.connect(refresh)
	
	tree.set_column_title(0, "Last Save        ")
	tree.set_column_title(1, "Title")
	tree.set_column_expand(0, false)
	tree.set_column_expand(1, true)
	tree.set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
	tree.set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_LEFT)
	
	tree.item_activated.connect(_on_item_activated)
	tree.button_clicked.connect(_on_item_button_clicked)
	
	reset()


func _on_filter_changed():
	var filter := filter_line_edit.text.to_lower()
	for item in items:
		var campaign_data: Dictionary = item.get_metadata(1)
		if filter and filter not in campaign_data.label.to_lower():
			item.visible = false
		else:
			item.visible = true
		

func _on_item_activated():
	var campaign_slug: String = item_selected.get_metadata(0)
	var campaign_data: Dictionary = item_selected.get_metadata(1)
	saved_campaign_hosted.emit(campaign_slug, campaign_data, steam_button.button_pressed)
	
	_on_close_button_pressed()


func _on_item_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button_index: int):
	item.select(0)
	var campaign_slug: String = item.get_metadata(0)
	var campaign_path := "user://campaigns".path_join(campaign_slug)
	match id:
		0: 
			_on_item_activated()
		1: 
			Utils.open_in_file_manager(campaign_path)
		2: 
			Utils.remove_dirs(campaign_path)
			refresh()


func refresh():
	tree.clear()
	items.clear()
	root = tree.create_item()
	
	var campaign_slugs := DirAccess.get_directories_at(campaigns_path)
	Debug.print_info_message("Campaigns: %s" % str(campaign_slugs))
	
	var filter := filter_line_edit.text.to_lower()
	
	for campaign_slug in campaign_slugs:
		var campaign_path := "user://campaigns".path_join(campaign_slug)
		var campaign_json := campaign_path.path_join("campaign.json")
		var campaign_data := Utils.load_json(campaign_json)
		var campaign_label: String = campaign_data.label
		if filter and filter not in campaign_label.to_lower():
			continue
		
		var item := root.create_child()
		
		var modified_time := FileAccess.get_modified_time(campaign_json)
		item.set_text(0, Time.get_date_string_from_unix_time(modified_time))
		#item.set_selectable(0, false)
		item.set_tooltip_text(0, "")
		item.set_text(1, campaign_label)
		item.set_tooltip_text(1, campaign_slug)
		
		item.add_button(1, PLAY_ICON, 0)
		item.set_button_color(1, 0, Color.DARK_GRAY)
		item.add_button(1, FOLDER_ICON, 1)
		item.set_button_color(1, 1, Color.DARK_GOLDENROD)
		item.add_button(1, REMOVE_ICON, 2)
		item.set_button_color(1, 2, Color.DARK_RED)
		
		item.set_metadata(0, campaign_slug)
		item.set_metadata(1, campaign_data)
		
		items.append(item)
