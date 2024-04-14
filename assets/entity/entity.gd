class_name Entity
extends Node3D


var level : Level

var is_edit_mode : bool
var is_editing : bool


func init(_level : Level, position_2d : Vector2):
	level = _level
	level.entities_parent.add_child(self)
	name = "Entity"
	position = Vector3(position_2d.x, 0, position_2d.y)
	return self


func _process(delta : float):
	if is_editing:
		var position_hovered = level.position_hovered
		if not Input.is_key_pressed(KEY_CTRL):
			position_hovered = position_hovered.snapped(Game.SNAPPING_QUARTER)
		position = lerp(position, Utils.v2_to_v3(position_hovered), 10 * delta)
