extends Node3D


@onready var floors_parent = $Floors
@onready var camera = $Camera
@onready var light = $OmniLight3D as OmniLight3D


func _ready():
	Game.camera = camera

	#DebugMenu.style = DebugMenu.Style.HIDDEN
	DebugMenu.style = DebugMenu.Style.VISIBLE_COMPACT
#	DebugMenu.style = DebugMenu.Style.VISIBLE_DETAILED
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	#DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	init_test_data()
	

func init_test_data():
	var floor_3d := Game.floor_3d_scene.instantiate() as Floor3D
	floors_parent.add_child(floor_3d)
	
	var wall := Game.wall_scene.instantiate().init(floor_3d) as Wall
	wall.add_point(Vector2(0, 2))
	wall.add_point(Vector2(0, 0))
	wall.add_point(Vector2(6, 0))
	wall.add_point(Vector2(6, 2))
	wall.is_edit_mode = true
	
	var wall2 := Game.wall_scene.instantiate().init(floor_3d) as Wall
	wall2.add_point(Vector2(0, 3))
	wall2.add_point(Vector2(0, 4))
	wall2.add_point(Vector2(6, 4))
	wall2.add_point(Vector2(6, 3))
	#wall2.is_edit_mode = true
	
	#light.position = Vector3(3, 1, 3)


#########
# input #
#########

func _input(event):
	if event is InputEventKey:
		if event.is_pressed():
			if event.keycode == KEY_F4:
				if DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
				else:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
					
			if event.keycode == KEY_F5:
				get_tree().reload_current_scene()
