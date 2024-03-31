class_name WallPoint
extends Control


signal changed()
signal selected(wall_point : WallPoint)
signal removed(wall_point : WallPoint)
signal edited(wall_point : WallPoint)
signal broken(wall_point : WallPoint)


var wall : Wall

var position_3d : Vector3 :
	set(value):
		position_3d = value
		changed.emit()

var index : int :
	set(value):
		wall.points_parent.move_child(self, value)
	get: 
		return wall.points_parent.get_children().find(self)


@onready var button := %Button as Button
@onready var label := %Label as Label
@onready var options := %Options as Control
@onready var add_after := %AddAfter as Button
@onready var add_before := %AddBefore as Button
@onready var delete_button := %DeleteButton as Button
@onready var break_button := %BreakButton as Button


func init(_wall : Wall, _index : int, _position_3d : Vector3):
	wall = _wall
	wall.points_parent.add_child(self)
	index = _index
	position_3d = _position_3d
	name = "WallPoint"
	return self


func _ready():
	wall.canvas_layer.visibility_changed.connect(_on_canvas_layer_visibility_changed)
	changed.connect(_on_changed)
	wall.curve_changed.connect(_on_changed)
	button.button_down.connect(_on_button_down)
	button.button_up.connect(_on_button_up)
	add_after.button_down.connect(_on_add_after_down)
	add_after.button_up.connect(_on_add_after_up)
	add_before.button_down.connect(_on_add_before_down)
	add_before.button_up.connect(_on_add_before_up)
	delete_button.button_down.connect(_on_delete_button_down)
	break_button.button_down.connect(_on_break_button_down)
	
	# init state
	_on_canvas_layer_visibility_changed()
	options.visible = false


func _on_canvas_layer_visibility_changed():
	if wall.canvas_layer.visible:
		Utils.safe_connect(Game.camera.changed, _on_changed)
		Utils.safe_connect(get_viewport().size_changed, _on_changed)
	else:
		options.visible = false
		Utils.safe_disconnect(Game.camera.changed, _on_changed)
		Utils.safe_disconnect(get_viewport().size_changed, _on_changed)
	
	
func _on_changed():
	visible = not Game.camera.eyes.is_position_behind(position_3d)
	position = Game.camera.eyes.unproject_position(position_3d + Vector3.UP * 0.001)  # x axis points cannot be unproject
	
	await get_tree().process_frame  # deletion of point need one frame to process
	label.text = str(index)


func _on_button_down():
	selected.emit(null)
	edited.emit(self)
	wall.editing_started.emit()

	
func _on_button_up():
	selected.emit(self)
	edited.emit(null)


func _on_add_after_down():
	var new_point = wall.add_point(wall.floor_3d.position_hovered, index + 1)
	edited.emit(new_point)

	
func _on_add_after_up():
	var new_point = wall.get_point_by_index(index + 1)
	selected.emit(new_point)
	edited.emit(null)


func _on_add_before_down():
	var new_point = wall.add_point(wall.floor_3d.position_hovered, index)
	edited.emit(new_point)

	
func _on_add_before_up():
	var new_point = wall.get_point_by_index(index - 1)
	selected.emit(new_point)
	edited.emit(null)


func _on_delete_button_down():
	removed.emit(self)


func _on_break_button_down():
	broken.emit(self)
