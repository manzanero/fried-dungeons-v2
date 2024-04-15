class_name Entity
extends Node3D


var level : Level

var target_position : Vector2
var is_edit_mode : bool
var is_editing : bool : 
	set(value):
		is_editing = value
		if not value:
			position = Utils.v2_to_v3(target_position)


func init(_level : Level, position_2d : Vector2):
	level = _level
	level.entities_parent.add_child(self)
	name = "Entity"
	position = Vector3(position_2d.x, 0, position_2d.y)
	return self


func _process(delta : float):
	if is_editing:
		target_position = level.position_hovered
		if not Input.is_key_pressed(KEY_CTRL):
			target_position = target_position.snapped(Game.SNAPPING_QUARTER)
		position = lerp(position, Utils.v2_to_v3(target_position), 10 * delta)
