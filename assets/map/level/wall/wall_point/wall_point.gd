class_name WallPoint
extends Control


signal changed()


var wall : Wall


var position_3d : Vector3 :
	set(value):
		position_3d = value
		changed.emit()

var index : int :
	set(value):
		wall.points.erase(self)
		wall.points.insert(value, self)
	get: 
		return wall.points.find(self)


@onready var button := %Button as Button
@onready var label := %Label as Label


func init(_wall : Wall, _index : int, _position_3d : Vector3):
	wall = _wall
	wall.level.map.points_parent.add_child(self)
	index = _index
	position_3d = _position_3d
	name = "WallPoint"
	visible = false
	return self


func _ready():
	changed.connect(_on_changed)
	button.button_down.connect(_on_button_down)
	button.button_up.connect(_on_button_up)
	

func _on_changed():
	if not wall.is_edit_mode:
		return
		
	visible = not wall.level.map.camera.eyes.is_position_behind(position_3d)
	position = wall.level.map.camera.eyes.unproject_position(position_3d + Vector3.UP * 0.001)  # x axis points cannot be unproject

	await get_tree().process_frame  # deletion of point need one frame to process
	
	label.text = str(index)


func _on_button_down():
	wall.select_point(null)
	wall.edit_point(self)
	Game.handled_input = true

	
func _on_button_up():
	wall.select_point(self)
	wall.edit_point(null)
