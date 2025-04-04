class_name Level
extends Node3D

static var SCENE := preload("res://assets/map/level/level.tscn")

signal element_selection(element: Element)
signal light_texture_updated()


class State:
	const KEEP := ""
	const GO_BACKGROUND := "Background"
	const GO_IDLE := "Idle"
	const GO_GROUND_EDITING := "GroundEditing"
	const GO_WALL_BUILDING := "WallBuilding"
	const GO_WALL_EDITING := "WallEditing"
	const GO_ELEMENT_INSTANCING := "ElementInstancing"
	

var map: Map

@export var walls_parent: Node3D
@export var elements_parent: Node3D
@export var selector: Selector

var refresh_light_frecuency := 0.1

var index := 0
var cells := {}
var walls := {}
var elements: Dictionary[String, Element] = {}
var elements_selected := {}

var rect: Rect2i : 
	set(value): viewport_3d.rect = value
	get: return viewport_3d.rect


var is_selected: bool :
	set(value): map.selected_level = self if value else null
	get: return map.selected_level == self and map.is_selected


var is_ground_hovered: bool
var exact_position_hovered: Vector2
var position_hovered: Vector2
var exact_ceilling_hovered: Vector2
var ceilling_hovered: Vector2
var tile_hovered: Vector2i
var selected_wall: Wall
var drag_offset: Vector2
var mouse_move: bool
var element_selected: Element :
	set(value):
		element_selected = value
		element_selection.emit(value)
	get:
		if is_instance_valid(element_selected):
			return element_selected
		return null
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
@onready var ground_collider: StaticBody3D = %GroundCollider

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
	
	is_selected = true
	return self


func _ready():
	var floor_atlas_texture: TileSetAtlasSource = floor_2d.tile_map.tile_set.get_source(0)
	floor_atlas_texture.texture = map.atlas_texture
	
	map.camera.changed.connect(_on_camera_changed)
	map.camera.fps_enabled.connect(func (value):
		Game.ui.selected_scene_tab.fade_transition.cover()
		get_tree().create_timer(0.2).timeout.connect(Game.ui.selected_scene_tab.fade_transition.uncover)
		if value:
			#ceilling_mesh_instance_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			ceilling_mesh_instance_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		else:
			_on_refreshed_light()
			ceilling_mesh_instance_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			
			#map.camera.eyes.position.z = map.camera.init_zoom
			follower_entity = null
	)
	ceilling_mesh_instance_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	
	# modes
	Game.modes.mode_changed.connect(update_mode)
	visibility_changed.connect(update_mode)
	Game.flow.changed.connect(func ():  # prevent keep draggin while pause in remote
		if is_instance_valid(element_selected):
			element_selected.is_dragged = false
	)
	change_state(State.GO_IDLE)
	
	map.darkvision_enabled.connect(_on_refreshed_light.unbind(1))
	
	#region light
	light_texture = light_viewport.get_texture()
	
	### if timer
	#refresh_light_timer.wait_time = refresh_light_frecuency
	#refresh_light_timer.timeout.connect(_on_refreshed_light)
	
	## if pixel shading
	#RenderingServer.global_shader_parameter_set("light_texture", light_texture)
	
	## if real time
	#light_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	#floor_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	#endregion


func _on_refreshed_light():
	if not is_selected:
		return
		
	# if not real time
	refresh_light()


func refresh_light():
	light_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	floor_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	light_sample_2d = light_texture.get_image()
	light_texture_updated.emit()


func _on_camera_changed():
	if follower_entity:
		follower_entity.target_position = map.camera.focus_hint_3d.global_position
		follower_entity.is_moving_to_target = true
		
		Game.server.rpcs.set_element_target.rpc(map.slug, index, follower_entity.id, 
				follower_entity.target_position, follower_entity.rotation)


func get_element_light(point: Vector2) -> Color:
	#return get_point_light(point)
	
	const NE_POINT := Vector2(Game.U, Game.U)
	const SE_POINT := Vector2(Game.U, -Game.U)
	const SW_POINT := Vector2(-Game.U, -Game.U)
	const NW_POINT := Vector2(-Game.U, Game.U)
	var ne := get_point_light(point + NE_POINT)
	var se := get_point_light(point + SE_POINT)
	var sw := get_point_light(point + SW_POINT)
	var nw := get_point_light(point + NW_POINT)
	return Color(
			max(ne.r, se.r, sw.r, nw.r), max(ne.g, se.g, sw.g, nw.g), 
			max(ne.b, se.b, sw.b, nw.b), max(ne.a, se.a, sw.a, nw.a))


func get_point_light(point: Vector2) -> Color:
	if not light_sample_2d:
		return Color.TRANSPARENT
	var pixel_position := (point - Vector2(rect.position)) * 4
	if pixel_position.x < 0 or pixel_position.x >= light_sample_2d.get_width():
		return Color.TRANSPARENT
	if pixel_position.y < 0 or pixel_position.y >= light_sample_2d.get_height():
		return Color.TRANSPARENT
	
	return light_sample_2d.get_pixelv(pixel_position)


func is_watched(point: Vector2) -> bool:
	return get_point_light(point).a > 0.001
	

func update_mode():
	if not is_selected:
		return
	
	change_mode(Game.modes.mode)
	
	
func change_mode(mode: ModeController.Mode):
	Debug.print_info_message("selected mode: %s" % ModeController.Mode.keys()[mode])

	match mode:
		ModeController.Mode.NONE:
			change_state(State.GO_IDLE)
		
		ModeController.Mode.GROUND_PAINT_TILE:
			change_state(State.GO_GROUND_EDITING)
			Game.ui.tab_builder.visible = true
		ModeController.Mode.GROUND_PAINT_RECT:
			change_state(State.GO_GROUND_EDITING)
			Game.ui.tab_builder.visible = true
		ModeController.Mode.GROUND_PAINT_BUCKET:
			change_state(State.GO_GROUND_EDITING)
			Game.ui.tab_builder.visible = true
		ModeController.Mode.GROUND_ERASE_RECT:
			change_state(State.GO_GROUND_EDITING)
			Game.ui.tab_builder.visible = true
		
		ModeController.Mode.WALL_BOUND:
			state_machine.get_state_node(State.GO_WALL_BUILDING).mode = LevelWallBuildingState.ONE_SIDED
			change_state(State.GO_WALL_BUILDING)
			Game.ui.tab_builder.visible = true
		ModeController.Mode.WALL_FENCE:
			state_machine.get_state_node(State.GO_WALL_BUILDING).mode = LevelWallBuildingState.TWO_SIDED
			change_state(State.GO_WALL_BUILDING)
			Game.ui.tab_builder.visible = true
		ModeController.Mode.WALL_BARRIER:
			state_machine.get_state_node(State.GO_WALL_BUILDING).mode = LevelWallBuildingState.BARRIER
			change_state(State.GO_WALL_BUILDING)
			Game.ui.tab_builder.visible = true
		ModeController.Mode.WALL_BOX:
			state_machine.get_state_node(State.GO_WALL_BUILDING).mode = LevelWallBuildingState.OBSTACLE
			change_state(State.GO_WALL_BUILDING)
			Game.ui.tab_builder.visible = true
		ModeController.Mode.WALL_PASSAGE:
			state_machine.get_state_node(State.GO_WALL_BUILDING).mode = LevelWallBuildingState.PASSAGE
			change_state(State.GO_WALL_BUILDING)
			Game.ui.tab_builder.visible = true
		
		ModeController.Mode.EDIT_SELECT_WALL:
			change_state(State.GO_WALL_EDITING)
			Game.ui.tab_builder.visible = true
		ModeController.Mode.EDIT_FLIP_WALL:
			state_machine.get_state_node(State.GO_WALL_BUILDING).mode = LevelWallBuildingState.FLIP_WALL
			change_state(State.GO_WALL_BUILDING)
			Game.ui.tab_builder.visible = true
		ModeController.Mode.EDIT_CHANGE_WALL:
			state_machine.get_state_node(State.GO_WALL_BUILDING).mode = LevelWallBuildingState.CHANGE_WALL
			change_state(State.GO_WALL_BUILDING)
			Game.ui.tab_builder.visible = true
		ModeController.Mode.EDIT_PAINT_WALL:
			state_machine.get_state_node(State.GO_WALL_BUILDING).mode = LevelWallBuildingState.PAINT_WALL
			change_state(State.GO_WALL_BUILDING)
			Game.ui.tab_builder.visible = true
		ModeController.Mode.EDIT_CUT_WALL:
			state_machine.get_state_node(State.GO_WALL_BUILDING).mode = LevelWallBuildingState.CUT_WALL
			change_state(State.GO_WALL_BUILDING)
			Game.ui.tab_builder.visible = true
		
		ModeController.Mode.LIGHT_OMNILIGHT:
			state_machine.get_state_node(State.GO_ELEMENT_INSTANCING).mode = LevelElementInstancingState.OMNILIGHT
			change_state(State.GO_ELEMENT_INSTANCING)
			Game.ui.tab_resources.visible = true
		
		ModeController.Mode.ENTITY_3D_SHAPE:
			state_machine.get_state_node(State.GO_ELEMENT_INSTANCING).mode = LevelElementInstancingState.ENTITY_3D
			change_state(State.GO_ELEMENT_INSTANCING)
			Game.ui.tab_resources.visible = true
		ModeController.Mode.ENTITY_BILLBOARD:
			state_machine.get_state_node(State.GO_ELEMENT_INSTANCING).mode = LevelElementInstancingState.ENTITY_BILLBOARD
			change_state(State.GO_ELEMENT_INSTANCING)
			Game.ui.tab_resources.visible = true
		
		ModeController.Mode.PROP_3D_SHAPE:
			state_machine.get_state_node(State.GO_ELEMENT_INSTANCING).mode = LevelElementInstancingState.PROP_3D
			change_state(State.GO_ELEMENT_INSTANCING)
			Game.ui.tab_resources.visible = true
		ModeController.Mode.PROP_DECAL:
			state_machine.get_state_node(State.GO_ELEMENT_INSTANCING).mode = LevelElementInstancingState.PROP_DECAL
			change_state(State.GO_ELEMENT_INSTANCING)
			Game.ui.tab_resources.visible = true


func change_state(state: String):
	Game.ui.state_label_value.text = state
	state_machine.change_state(state)
	

var next_update_process_frame := 0
var next_update_ticks_msec := 0

func _process(_delta: float) -> void:
	if not is_selected:
		return
		
	if next_update_ticks_msec < Game.ticks_msec and next_update_process_frame < Game.process_frame:
		next_update_ticks_msec = Game.ticks_msec + 100
		next_update_process_frame = Game.process_frame + 6
		refresh_light()
		
		# can i improve this?
		map.camera.allow_fp = [
			is_watched(map.camera.position_2d),
			is_watched(map.camera.position_2d + 0.25 * Vector2.UP),
			is_watched(map.camera.position_2d + 0.25 * Vector2.RIGHT),
			is_watched(map.camera.position_2d + 0.25 * Vector2.DOWN),
			is_watched(map.camera.position_2d + 0.25 * Vector2.LEFT),
		].all(func (x): return x)


func set_cell_data(tile: Vector2i, tile_data: Dictionary):
	cells[tile] = Level.Cell.new(tile_data.i, tile_data.f)
	viewport_3d.tile_map_set_cell(tile, Vector2i(tile_data.f, tile_data.i))


func remove_cell(tile: Vector2i):
	cells.erase(tile)
	viewport_3d.tile_map_remove_cell(tile)
		

func select(thing):
	if thing is Wall:
		thing.is_selected = true
		selected_wall = thing
		for wall in walls_parent.get_children():
			if wall != thing:
				wall.is_selected = false
		
	else:
		selected_wall = null
		for wall in walls_parent.get_children():
			wall.is_selected = false


func set_master_control():
	for entity: Element in Game.ui.selected_map.selected_level.elements.values():
		entity.is_selectable = true
		if entity is Entity:
			entity.eye.visible = false
			
	#Game.ui.selected_map.selected_level.refresh_light()
	#for element: Element in Game.ui.selected_map.selected_level.elements.values():
		#element.update_light()
	

func set_control(control_elements: Dictionary):
	var elements_under_control := control_elements.keys()
	for entity: Element in Game.ui.selected_map.selected_level.elements.values():
		if entity is Entity:
			if entity.label in elements_under_control:
				var entity_control_data: Dictionary = control_elements[entity.label]
				entity.is_selectable = entity_control_data.get("movement", false)
				entity.eye.visible = entity_control_data.get("senses", false)
				
				Debug.print_info_message("Player got control of \"%s\"" % entity.label)
				
			else:
				entity.is_selectable = false
				entity.eye.visible = false
		else:
			entity.is_selectable = false

	#Game.ui.selected_map.selected_level.refresh_light()
	#for element: Element in Game.ui.selected_map.selected_level.elements.values():
		#element.update_light()


#region input

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			mouse_move = false
			
	elif event is InputEventMouseMotion:
		mouse_move = true
		#mouse_move = event.relative != Vector2.ZERO

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
