class_name Eye
extends Node3D

@export var entitiy: Entity

var LIGHT_SPECULAR := 16.0
var ATTENUATION := 3.5
		
	
var blindness := false :
	set(value): blindness = value; _set_vision()
	
var visibility_range := 1.0 :
	set(value): visibility_range = value; _set_vision()

var darkvision_enabled := false :
	set(value): darkvision_enabled = value; _set_vision()

var darkvision := 1.0 :
	set(value): darkvision = value; _set_vision()


func _set_vision():
	vision_range_light.visible = not blindness
	blindness_range_light.visible = blindness and darkvision_enabled
	darkvision_light.visible = darkvision_enabled
	
	vision_range_light.light_specular = LIGHT_SPECULAR * visibility_range ** ATTENUATION
	blindness_range_light.light_specular = LIGHT_SPECULAR * 0.1 ** ATTENUATION
	darkvision_light.omni_range = darkvision
	#if blindness:
		#blindness_range_light.light_specular = LIGHT_SPECULAR * 0.1 ** ATTENUATION
		##blindness_range_light.light_specular = LIGHT_SPECULAR * (darkvision / 10) ** ATTENUATION
	#else:
		#blindness_range_light.light_specular = LIGHT_SPECULAR * visibility_range ** ATTENUATION


@onready var vision_range_light: OmniLight3D = %VisionRangeLight
@onready var blindness_range_light: OmniLight3D = %BlindnessRangeLight
@onready var darkvision_light: OmniLight3D = %DarkvisionLight


func _ready() -> void:
	vision_range_light.light_specular = LIGHT_SPECULAR
	vision_range_light.omni_attenuation = ATTENUATION
	blindness_range_light.light_specular = LIGHT_SPECULAR
	blindness_range_light.omni_attenuation = ATTENUATION
