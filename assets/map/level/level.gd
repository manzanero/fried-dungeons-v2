class_name Level
extends Node3D

static var SCENE := preload("res://assets/map/level/level.tscn")

signal element_selection(element: Element)


@export var map: Map

@export var walls_parent: Node3D
@export var elements_parent: Node3D

@export var selector: Selector

@export var refresh_light_frecuency := 0.1

var index := 0
var cells := {}
var elements := {}
var walls := {}

var rect: Rect2i : 
	set(value):
		rect = value
		viewport_3d.rect = value
	get:
		return viewport_3d.rect

var is_ground_hovered: bool
var exact_position_hovered: Vector2
var position_hovered: Vector2
var ceilling_hovered: Vector2
var tile_hovered: Vector2i
var selected_wall: Wall
var drag_offset: Vector2
var element_selected: Element :
	set(value):
		element_selected = value
		element_selection.emit(value)
var preview_element: Element
var follower_entity: Entity :
	set(value):
		if follower_entity:
			follower_entity.body.visible = true
			follower_entity.is_dragged = false
		follower_entity = value
		if follower_entity:
			follower_entity.body.visible = false
			follower_entity.is_selected = false
			map.camera.target_position.global_position = follower_entity.global_position + 0.5 * Vector3.UP
			map.camera.is_fps = true
			
var active_lights: Array[Light] = []

var light_sample_2d: Image

func get_entity_by_id(element_id) -> Entity:
	var element: Element = elements_parent.get_node(element_id)
	if not element:
		Debug.print_error_message("Entity \"%s\" (%s) not found" % [element.label, element.id])
	return element
	

@onready var state_machine: StateMachine = $StateMachine

@onready var viewport_3d: Viewport3D = %Viewport3D
@onready var floor_viewport := viewport_3d.floor_viewport
@onready var floor_2d := viewport_3d.floor_2d

@onready var refresh_light_timer: Timer = %RefreshLightTimer
@onready var light_viewport: SubViewport = viewport_3d.light_viewport
@onready var light_camera := viewport_3d.light_camera
@onready var light_texture: ViewportTexture

@onready var ceilling_mesh_instance_3d: MeshInstance3D = $Ceilling/MeshInstance3D


func init(_map: Map, _index: int) -> Level:
	map = _map
	index = _index
	map.levels[index] = self
	map.selected_level = self
	map.levels_parent.add_child(self)
	return self


func _ready():
	var floor_atlas_texture: TileSetAtlasSource = floor_2d.tile_map.tile_set.get_source(0)
	#var floor_atlas_texture := TileSetAtlasSource.new()
	floor_atlas_texture.texture = map.atlas_texture 
	###var tile_set := TileSet.new()
	##tile_set.add_source(floor_atlas_texture, 0)
	##floor_2d.tile_map.tile_set = tile_set
	#
	#var tile_set := floor_2d.tile_map.tile_set.duplicate(true)
	#floor_2d.tile_map.tile_set = tile_set
	#
	map.camera.changed.connect(_on_camera_changed)
	map.camera.fps_enabled.connect(func (value):
		Game.ui.selected_scene_tab.fade_transition.cover()
		get_tree().create_timer(0.2).timeout.connect(Game.ui.selected_scene_tab.fade_transition.uncover)
		if value:
			ceilling_mesh_instance_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		else:
			_on_refreshed_light()
			ceilling_mesh_instance_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			
			#map.camera.eyes.position.z = map.camera.init_zoom
			follower_entity = null
	)
	ceilling_mesh_instance_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	
	state_machine.change_state("Idle")
	
	#region light
	light_texture = light_viewport.get_texture()
	refresh_light_timer.wait_time = refresh_light_frecuency
	refresh_light_timer.timeout.connect(_on_refreshed_light)
	
	## if pixel shading
	#RenderingServer.global_shader_parameter_set("light_texture", light_texture)
	
	## if real time
	#light_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	#floor_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	#endregion


func _on_refreshed_light():
	
	# if not real time
	light_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	floor_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	light_sample_2d = light_texture.get_image()


func _on_camera_changed():
	if follower_entity:
		follower_entity.target_position = map.camera.focus_hint_3d.global_position
		follower_entity.is_moving_to_target = true
		
		Game.server.rpcs.set_element_target.rpc(map.slug, index, follower_entity.id, 
				follower_entity.target_position, follower_entity.rotation)


func get_light(point: Vector2) -> Color:
	if not light_sample_2d:
		return Color.TRANSPARENT
	var pixel_position := (point - Vector2(rect.position)) * 4 
	if pixel_position.x < 0 or pixel_position.x >= light_sample_2d.get_width():
		return Color.TRANSPARENT
	if pixel_position.y < 0 or pixel_position.y >= light_sample_2d.get_height():
		return Color.TRANSPARENT
	
	return light_sample_2d.get_pixelv(pixel_position)


func is_watched(point: Vector2) -> bool:
	return get_light(point).a


func _process(_delta: float) -> void:
	if Game.campaign and Game.campaign.is_master and Game.ui.is_mouse_over_scene_tab:
		
		# Delete without ask
		if Input.is_action_just_pressed("force_delete"):
			if is_instance_valid(selected_wall):
				selected_wall.remove()
				
				Game.server.rpcs.remove_wall.rpc(map.slug, index, selected_wall.id)
				
			if is_instance_valid(element_selected):
				element_selected.remove()
				
				Game.server.rpcs.remove_element.rpc(map.slug, index, element_selected.id)
				
		elif Input.is_action_just_pressed("delete"):
			if is_instance_valid(selected_wall):
				selected_wall.remove()
				
				Game.server.rpcs.remove_wall.rpc(map.slug, index, selected_wall.id)
				
			if is_instance_valid(element_selected):
				Game.ui.mouse_blocker.visible = true
				Game.ui.delete_element_window.visible = true
				Game.ui.delete_element_window.element_selected = element_selected
				
				var response = await Game.ui.delete_element_window.response
				if response:
					element_selected.remove()
					Game.server.rpcs.remove_element.rpc(map.slug, index, element_selected.id)


func build_point(tile: Vector2i, tile_data: Dictionary):
	cells[tile] = Level.Cell.new(tile_data.i, tile_data.f)
	viewport_3d.tile_map_set_cell(tile, Vector2i(tile_data.f, tile_data.i))


#region input

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Debug.print_debug_message("Tile clicked: %s" % tile_hovered)


#endregion

#region objects 

class Cell:
	var index: int
	var frame: int

	func _init(_index, _frame) -> void:
		index = _index
		frame = _frame
	
	func json() -> Dictionary:
		return {"i": index, "f": frame}


#endregion

#region serializing

func json() -> Dictionary:
	var pos_x := rect.position.x
	var pos_z := rect.position.y
	var len_x := rect.size.x
	var len_z := rect.size.y
	
	var tiles := []
	tiles.resize(len_z)
	for y in range(len_z):
		var row := []
		row.resize(len_x)
		tiles[y] = row
	for tile in cells:
		var cell: Cell = cells[tile]
		tiles[tile.y - pos_z][tile.x - pos_x] = cell.json()
		
	var walls_data := []
	for wall in walls_parent.get_children():
		walls_data.append(wall.json())
		
	var elements_data := []
	for element: Element in elements.values():
		if not element or not is_instance_valid(element):
			Debug.print_warning_message("Element \"%s\" was freed" % element.id)
			continue
		if not element.is_preview:
			elements_data.append(element.json())
		
	var level := {
		"rect": {
			"position": Utils.v2_to_a2(rect.position),
			"size": Utils.v2_to_a2(rect.size),
		},
		"tiles": tiles,
		"walls": walls_data,
		"elements": elements_data,
	}
	
	return level


#endregion
