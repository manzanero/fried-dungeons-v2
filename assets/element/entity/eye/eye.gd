class_name Eye
extends Node3D

@onready var omni_light_3d: OmniLight3D = %OmniLight3D
@onready var darkvision_light: OmniLight3D = %DarkvisionLight


#func _process(_delta: float) -> void:
	#omni_light_3d.position.y = 1. / 128. * (1 + Game.wave_global)
	#pass
