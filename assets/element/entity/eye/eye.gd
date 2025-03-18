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


@onready var vision_range_light: OmniLight3D = %VisionRangeLight
@onready var blindness_range_light: OmniLight3D = %BlindnessRangeLight
@onready var darkvision_light: OmniLight3D = %DarkvisionLight


var visibility_range_tween: Tween = null
var darkvision_light_tween: Tween = null

func _set_vision():
	if visibility_range_tween:
		visibility_range_tween.kill()
	visibility_range_tween = create_tween()
	visibility_range_tween.tween_property(vision_range_light, "light_specular", 
			LIGHT_SPECULAR * visibility_range ** ATTENUATION, 0.1)
	vision_range_light.visible = not blindness
	
	blindness_range_light.visible = blindness and darkvision_enabled
	blindness_range_light.light_specular = LIGHT_SPECULAR * 0.1 ** ATTENUATION
	
	darkvision_light.visible = darkvision_enabled
	#darkvision_light.omni_range = 1.0 if blindness else darkvision
	
	if darkvision_light_tween:
		darkvision_light_tween.kill()
	darkvision_light_tween = create_tween()
	darkvision_light_tween.tween_property(darkvision_light, "omni_range", 1.0 if blindness else darkvision, 0.1)


func _ready() -> void:
	vision_range_light.light_specular = LIGHT_SPECULAR
	vision_range_light.omni_attenuation = ATTENUATION
	blindness_range_light.light_specular = LIGHT_SPECULAR
	blindness_range_light.omni_attenuation = ATTENUATION
