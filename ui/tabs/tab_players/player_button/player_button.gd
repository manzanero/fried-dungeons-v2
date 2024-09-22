class_name PlayerButton
extends Control


const PLAYER_ENTITY_BUTTON = preload("res://ui/tabs/tab_players/player_button/player_entity_button/player_entity_button.tscn")


@onready var icon: TextureRect = %IconTexture
@onready var username_label: Label = %UsernameLabel
@onready var slug_label: Label = %SlugLabel
@onready var button: Button = %Button

@onready var player_entities_parent: Control = %PlayerEntities


var slug: String : 
	set(value):
		slug = value
		slug_label.text = value
var username: String : 
	set(value):
		username = value
		username_label.text = value
var texture: Texture2D : 
	set(value):
		texture = value
		icon.texture = texture


var player_entities_data := {}


func init(tab_players: TabPlayers, _slug: String, _username: String, _texture: Texture2D, 
		_player_entities_data: Dictionary):
	tab_players.player_buttons.add_child(self)
	slug = _slug
	username = _username
	texture = _texture
	player_entities_data = _player_entities_data
	for entity_id in player_entities_data:
		_init_player_entity_button(entity_id)
	
	button.pressed.connect(func (): 
		Game.ui.tab_players.player_slug_selected = slug
	)

	return self

func _init_player_entity_button(entity_id: String):
	var player_entity: Button
	if player_entities_parent.has_node(entity_id):
		player_entity = player_entities_parent.get_node(entity_id)
	else:
		player_entity = PLAYER_ENTITY_BUTTON.instantiate()
		player_entities_parent.add_child(player_entity)
	player_entity.name = entity_id
	player_entity.text = player_entities_data[entity_id].label
	player_entity.tooltip_text = entity_id
	player_entity.left_button_pressed.connect(func ():
		button.button_pressed = true
		Game.ui.tab_players.player_slug_selected = slug
		
		var entity: Entity = Game.ui.selected_map.selected_level.elements.get(entity_id)
		if entity:
			entity.is_selected = true
			entity.map.camera.target_position.position = entity.position + Vector3.UP * 0.5
	)
	player_entity.right_button_pressed.connect(func ():
		player_entity.queue_free()
		player_entities_data.erase(entity_id)
		Game.ui.tab_players.save(slug)
		
		Debug.print_info_message("Entity \"%s\" removed from player \"%s\"" % [entity_id, slug])
	)

func add_player_entity(entity: Entity):
	player_entities_data[entity.id] = {
		"label": entity.label
	}
	_init_player_entity_button(entity.id)


#func remove_player_entity(entity: Entity):
	#player_entities[entity.id].queue_free()
