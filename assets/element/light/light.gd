class_name Light
extends Element


@export var range_radius := 5.0 :
	set(value):
		range_radius = value
		if omni_light_3d:
			omni_light_3d.omni_range = value

@export var active := true :
	set(value):
		active = value
		omni_light_3d.visible = value
		
		if active:
			level.active_lights.append(self)
			inner_material.albedo_color = Color(0.75, 0.75, 0.75, 0.5)
			
			# Only a certain number of lights can be active at a time
			if level.active_lights.size() > Game.MAX_LIGHTS:
				Debug.print_message(Debug.ERROR, "Max. lights exceeded")
				var first_light : Light = level.active_lights.pop_front()
				first_light.active = false
				
		else:
			level.active_lights.erase(self)
			inner_material.albedo_color = Color.BLACK

@export var light_color := Color.WHITE :
	set(value):
		color = value
		if omni_light_3d:
			outer_material.albedo_color = value
			omni_light_3d.light_color = value

var hidden := true :
	set(value):
		hidden = value
		body.visible = not value


@onready var omni_light_3d := $OmniLight3D as OmniLight3D
@onready var body = $Body as Node3D
@onready var inner_mesh := %InnerMesh as MeshInstance3D
@onready var inner_material := inner_mesh.get_surface_override_material(0) as StandardMaterial3D
@onready var outer_mesh := %OuterMesh as MeshInstance3D
@onready var outer_material := outer_mesh.get_surface_override_material(0) as StandardMaterial3D
@onready var line_renderer_3d := %LineRenderer3D as LineRenderer


func _ready() -> void:
	line_renderer_3d.disabled = true
	line_renderer_3d.points.clear()
	line_renderer_3d.points.append_array([Vector3.ZERO, Vector3.UP * 0.75])


func _set_selected(value: bool) -> void:
	is_selected = value
	if value:
		level.element_selected = self
		Game.ui.tab_properties.element_selected = self
	elif Game.ui.tab_properties.element_selected == self:
		Game.ui.tab_properties.element_selected = null
		
	line_renderer_3d.disabled = not value


## Properties

const SHOW_LABEL = "show_label"
const LABEL = "label"
const ACTIVE = "active"
const RANGE = "range"
const COLOR = "color"


func _init_property_list(_properties):
	var init_properties = [
		["info", ACTIVE, Property.Hints.BOOL, _properties.get(ACTIVE, true)],
		["info", LABEL, Property.Hints.STRING, _properties.get(LABEL, "Unknown")],
		["info", SHOW_LABEL, Property.Hints.BOOL, _properties.get(SHOW_LABEL, true)],
		["light", RANGE, Property.Hints.FLOAT, _properties.get(RANGE, 5)],
		["light", COLOR, Property.Hints.COLOR, _properties.get(COLOR, Color.WHITE)],
	]
	for property_array in init_properties:
		init_property(property_array[0], property_array[1], property_array[2], property_array[3])
		change_property(property_array[1], property_array[3])


func _on_property_changed(property_name: String, _old_value: Variant, new_value: Variant) -> void:
	change_property(property_name, new_value)
	

func change_property(property_name: String, new_value: Variant) -> void:
	match property_name:
		ACTIVE:
			active = new_value
		LABEL:
			label = new_value
		RANGE:
			range_radius = new_value
		COLOR:
			light_color = new_value


###############
# Serializing #
###############

func json():
	var values := {}
	for property in properties:
		values[property] = properties[property].get_raw()
		
	return {
		"type": "light",
		"id": id,
		"position": Utils.v3_to_a2(position),
		"rotation": snappedf(rotation_y, 0.001),
		"properties": values,
	}
