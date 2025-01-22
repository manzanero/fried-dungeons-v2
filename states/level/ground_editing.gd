class_name LevelGroundEditingState
extends LevelBaseState


var material_selected_index: int :
	get: return Game.ui.tab_builder.material_index_selected

var material_selected_frames: int :
	get:
		var frames: int = Game.DEFAULT_INDEX_TEXTURE_ATTRS.frames
		var atlas_texture_resource := map.atlas_texture_resource
		if atlas_texture_resource:
			frames = atlas_texture_resource.attributes.get("frames", frames)
		return frames


var _click_origin_position := Game.NULL_POSITION_2D
var _click_origin_tile := Game.NULL_TILE
var _is_rect_being_builded := false


var _is_something_being_builded: bool :
	get: return _is_rect_being_builded


func _enter_state(previous_state: String) -> void:
	super(previous_state)
	Game.ui.build_border.visible = true
	
	selector.grid.visible = true
	selector.position_2d = Game.NULL_POSITION_2D
	selector.column.visible = false


func _exit_state(next_state: String) -> void:
	super(next_state)
	Game.ui.build_border.visible = false
	
	selector.wall.mesh = null
	selector.grid.visible = false
	selector.column.visible = false
	_is_rect_being_builded = false


func _physics_process_state(_delta: float) -> String:
	if not map.is_selected or not level.is_selected:
		return Level.State.GO_BACKGROUND
	
	process_ground_hitted()
	process_change_grid()
	
	if Input.is_action_just_pressed("key_c"):
		Game.ui.tab_builder.material_index_selected = level.cells[level.tile_hovered].index
	
	if Input.is_action_just_pressed("ui_cancel") and not _is_something_being_builded:
		Game.modes.reset()
		return Level.State.GO_IDLE
	
	match Game.modes.mode:
		ModeController.Mode.GROUND_PAINT_TILE:
			process_build_point()
		ModeController.Mode.GROUND_PAINT_RECT:
			process_build_rect()
		ModeController.Mode.GROUND_PAINT_BUCKET:
			process_paint_bucket()
		ModeController.Mode.GROUND_ERASE_RECT:
			process_erase_rect()
			
	return Level.State.KEEP


func process_build_point() -> void:
	if Input.is_action_just_pressed("left_click") and Game.ui.is_mouse_over_scene_tab:
		selector.area.visible = true
		
	if Input.is_action_pressed("left_click") and _click_origin_tile != level.tile_hovered and Game.ui.is_mouse_over_scene_tab:
		var tile := level.tile_hovered
		_click_origin_tile = tile
		selector.tiled_move_area_to(level.position_hovered, level.position_hovered)
		var random = range(material_selected_frames).pick_random()
		var tile_data := {"i": material_selected_index, "f": random}
		level.set_cell_data(tile, tile_data)
		Game.server.rpcs.set_cell.rpc(map.slug, level.index, tile, tile_data)
	
	if Input.is_action_just_released("left_click"):
		selector.area.visible = false
		_click_origin_tile = Game.NULL_TILE


func process_build_rect() -> void:
	if Input.is_action_just_pressed("right_click"):
		selector.area.visible = false
		_is_rect_being_builded = false
		
	if Input.is_action_just_pressed("left_click") and Game.ui.is_mouse_over_scene_tab:
		_click_origin_position = level.position_hovered
		_is_rect_being_builded = true
		selector.area.visible = true
		
	if Input.is_action_pressed("left_click") and Game.ui.is_mouse_over_scene_tab:
		selector.tiled_move_area_to(_click_origin_position, level.position_hovered)
		
	if Input.is_action_just_released("left_click") and _is_rect_being_builded:
		selector.area.visible = false
		_is_rect_being_builded = false
		
		var init_x := int(_click_origin_position.floor().x)
		var init_y := int(_click_origin_position.floor().y)
		var end_x := level.tile_hovered.x
		var end_y := level.tile_hovered.y
		var dir_x := 1 if end_x > init_x else -1
		var dir_y := 1 if end_y > init_y else -1
		var frames := material_selected_frames
		for x in range(init_x, end_x + dir_x, dir_x):
			for y in range(init_y, end_y + dir_y, dir_y):
				var random = range(frames).pick_random()
				var tile := Vector2i(x, y)
				var tile_data := {"i": material_selected_index, "f": random}
				level.set_cell_data(tile, tile_data)
				Game.server.rpcs.set_cell.rpc(map.slug, level.index, tile, tile_data)


func process_erase_rect() -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		selector.area.visible = false
		_is_rect_being_builded = false
		
	if Input.is_action_just_pressed("left_click") and Game.ui.is_mouse_over_scene_tab:
		_click_origin_position = level.position_hovered
		_is_rect_being_builded = true
		selector.area.visible = true
		
	if Input.is_action_pressed("left_click") and Game.ui.is_mouse_over_scene_tab:
		selector.tiled_move_area_to(_click_origin_position, level.position_hovered)
		
	if Input.is_action_just_released("left_click") and _is_rect_being_builded:
		selector.area.visible = false
		_is_rect_being_builded = false
		
		var init_x := int(_click_origin_position.floor().x)
		var init_y := int(_click_origin_position.floor().y)
		var end_x := level.tile_hovered.x
		var end_y := level.tile_hovered.y
		var dir_x := 1 if end_x > init_x else -1
		var dir_y := 1 if end_y > init_y else -1
		for x in range(init_x, end_x + dir_x, dir_x):
			for y in range(init_y, end_y + dir_y, dir_y):
				var tile := Vector2i(x, y)
				level.remove_cell(tile)
				Game.server.rpcs.remove_cell.rpc(map.slug, level.index, tile)


func process_paint_bucket() -> void:
	if Input.is_action_just_pressed("left_click") and Game.ui.is_mouse_over_scene_tab:
		selector.area.visible = true
		
	if Input.is_action_pressed("left_click") and _click_origin_tile != level.tile_hovered and Game.ui.is_mouse_over_scene_tab:
		_click_origin_tile = level.tile_hovered
		selector.tiled_move_area_to(level.position_hovered, level.position_hovered)
	
	if Input.is_action_just_released("left_click"):
		var tile := _click_origin_tile
		if tile == Game.NULL_TILE:
			return
		
		var new_index := material_selected_index
		var old_index := -1
		var cell: Level.Cell = level.cells.get(tile)
		if cell:
			old_index = cell.index
		var frames := material_selected_frames
		paint_tile_and_neighbours(tile, new_index, old_index, frames)
		
		selector.area.visible = false
		_click_origin_tile = Game.NULL_TILE


func paint_tile_and_neighbours(tile: Vector2, new_index: int, old_index: int, frames: int):
	paint_tile(tile, new_index, frames)
	if new_index == old_index:
		return
	
	for neighbour in get_neighbours(tile):
		var neighbour_cell: Level.Cell = level.cells.get(neighbour)
		if neighbour_cell:
			var neighbour_index = neighbour_cell.index
			if neighbour_index == old_index:
				paint_tile_and_neighbours(neighbour, new_index, old_index, frames)


func paint_tile(tile: Vector2, index: int, frames: int):
	var random = range(frames).pick_random()
	var tile_data := {"i": index, "f": random}
	level.set_cell_data(tile, tile_data)
	Game.server.rpcs.set_cell.rpc(map.slug, level.index, tile, tile_data)


func get_neighbours(tile: Vector2) -> Array[Vector2i]:
	return [
		tile + Vector2.UP,
		tile + Vector2.RIGHT,
		tile + Vector2.LEFT,
		tile + Vector2.DOWN,
	]
