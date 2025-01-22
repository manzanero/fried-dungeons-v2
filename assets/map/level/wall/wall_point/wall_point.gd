class_name WallPoint
extends Node3D


signal removed


var wall: Wall

var is_selected: bool :
	set(value):
		is_selected = value
		wall.refresh_highlight()

var is_hovered: bool :
	set(value):
		is_hovered = value
		wall.refresh_highlight()

var position_2d: Vector2 :
	set(value): 
		position = Utils.v2_to_v3(value)
		wall.curve.set_point_position(index, position)
		wall.refresh()
	get: 
		return Utils.v3_to_v2(position)

var position_3d: Vector3 :
	set(value): 
		position = value
		wall.curve.set_point_position(index, position)
		wall.refresh_mesh()
	get: 
		return position

var index: int :
	set(value):
		wall.points.erase(self)
		wall.points.insert(value, self)
	get:
		var _index = wall.points.find(self)
		if _index == -1:
			Debug.print_error_message("Wall is corrupted %s" % wall.points_position_2d)
		return _index
		
var is_first: bool :
	get: return index == 0
	
var is_last: bool :
	get: return index == wall.curve.point_count - 1


@onready var selector: WallPointSelector = $WallPointSelector


func init(_wall: Wall, _index: int, _position_3d: Vector3):
	wall = _wall
	wall.points_parent.add_child(self)
	index = _index
	position_3d = _position_3d
	return self


func remove():
	removed.emit()
