class_name TabMap
extends Control

@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var world_3d: World3D = sub_viewport.world_3d

@onready var map: Map = %Map

@onready var cursor_control: Control = $CursorControl

var is_mouse_over := false


func init(map_slug: String, map_data: Dictionary):
	Game.ui.map_tabs.add_child(self)
	
	#map.init_test_data()
	map.loader.load_map(map_data)
	map.slug = map_slug
	for level: Level in map.levels_parent.get_children():
		level.light_viewport.find_world_3d()
		
	name = map_data.label
	return self


func _ready() -> void:
	cursor_control.visible = true
	
	mouse_entered.connect(func(): 
		is_mouse_over = true
		
		# prevent have previous shape
		cursor_control.visible = false
		
		# prevent move focus when controlling cam with arrows
		focus_mode = FOCUS_ALL
		grab_focus()
		focus_mode = FOCUS_NONE
	)
	mouse_exited.connect(func():
		is_mouse_over = false
		
		cursor_control.visible = true
	)
	
	cursor_control.gui_input.connect(func (_event: InputEvent):
		cursor_control.visible = false
	)
