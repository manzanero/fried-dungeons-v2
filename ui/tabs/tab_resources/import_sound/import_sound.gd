class_name ImportSound
extends Control

signal attributes_changed(resource: CampaignResource, attributes: Dictionary)

const DEFAULT_VOLUME := 0.10
const DEFAULT_PITCH := 1.0

var resource: CampaignResource: set = _set_resource
var attributes: Dictionary : set = _set_attributes, get = _get_attributes


@onready var attribute_fields := {
	"volume": %VolumeField,
	"pitch": %PitchField,
}

@onready var reset_button: Button = %ResetButton
@onready var sound_edited_label: Label = %SoundEditedLabel


func _set_resource(_resource: CampaignResource) -> void:
	resource = _resource
	if not resource:
		return
		
	sound_edited_label.text = resource.path
	attributes = Game.campaign.get_resource_data(resource.path).get("attributes", {})


func _set_attributes(_attributes: Dictionary) -> void:
	reset()
	if _attributes.has("volume"):
		attribute_fields.volume.property_value = _attributes.volume * 100.0
	if _attributes.has("pitch"):
		attribute_fields.pitch.property_value = _attributes.pitch * 100.0


func _get_attributes() -> Dictionary:
	return {
		"volume": attribute_fields.volume.property_value / 100.0,
		"pitch": attribute_fields.pitch.property_value / 100.0,
	}


func reset() -> void:
	attribute_fields.volume.property_value = DEFAULT_VOLUME * 100.0
	attribute_fields.pitch.property_value = DEFAULT_PITCH * 100.0
	

func _ready() -> void:
	for attribute_field in attribute_fields.values():
		attribute_field.value_changed.connect(_on_attributes_changed.unbind(2))
	
	reset_button.pressed.connect(_on_reset_button_pressed)


func _on_attributes_changed() -> void:
	attributes_changed.emit(resource, attributes)


func _on_reset_button_pressed() -> void:
	reset()
