class_name Projectile
extends RigidBody2D

@export var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D
@export var sprite_2d: Sprite2D


func _ready():
	visible_on_screen_notifier_2d.screen_exited.connect(_on_screen_exited)
	angular_velocity = randf_range(-10, 10)


func _on_screen_exited():
	queue_free()
