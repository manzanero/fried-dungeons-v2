class_name Light
extends Element


var cached_light: Color :
	set(value): cached_light = value; 
	
var is_watched: bool : 
	get: return cached_light.a

## properties
var range_radius := 5.0 :
	set(value):
		range_radius = value
		omni_light_3d.omni_range = value

var active := true :
	set(value):
		active = value
		omni_light_3d.visible = value
		
		if active:
			level.active_lights.append(self)
			inner_material.albedo_color = Color(0.75, 0.75, 0.75, 0.5)
			
			# Only a certain number of lights can be active at a time
			if level.active_lights.size() > Game.MAX_LIGHTS:
				Debug.print_message(Debug.ERROR, "Max. lights exceeded")
				var first_light: Light = level.active_lights.pop_front()
				first_light.active = false
				
		else:
			level.active_lights.erase(self)
			inner_material.albedo_color = Color.BLACK

var light_color := Color.WHITE :
	set(value):
		light_color = value
		color = value
		outer_material.albedo_color = value
		omni_light_3d.light_color = value

var hidden := true :
	set(value): hidden = value; body.visible = not value


var dirty_light := false
var dirty_mesh := false


@onready var omni_light_3d := $OmniLight3D as OmniLight3D
@onready var body = $Body as Node3D
@onready var inner_mesh := %InnerMesh as MeshInstance3D
@onready var inner_material := inner_mesh.get_surface_override_material(0) as StandardMaterial3D
@onready var outer_mesh := %OuterMesh as MeshInstance3D
@onready var outer_material := outer_mesh.get_surface_override_material(0) as StandardMaterial3D
@onready var line_renderer_3d := %LineRenderer3D as LineRenderer


## properties
const LABEL := "label"; const LABEL_DEFAULT_VALUE := "Light Unknown"
const DESCRIPTION := "description"; const DESCRIPTION_DEFAULT_VALUE := ""
const ACTIVE = "active"; const ACTIVE_DEFAULT_VALUE := true
const RANGE = "range"; const RANGE_DEFAULT_VALUE := 5.0
const COLOR = "color"; const COLOR_DEFAULT_VALUE := Color.WHITE


func _ready() -> void:
	init_properties = [
		["info", LABEL, Property.Hints.STRING, LABEL_DEFAULT_VALUE],
		["info", DESCRIPTION, Property.Hints.STRING, DESCRIPTION_DEFAULT_VALUE],
		["physics", ACTIVE, Property.Hints.BOOL, ACTIVE_DEFAULT_VALUE],
		["physics", RANGE, Property.Hints.FLOAT, RANGE_DEFAULT_VALUE],
		["physics", COLOR, Property.Hints.COLOR, COLOR_DEFAULT_VALUE],
	]
	line_renderer_3d.disabled = true
	line_renderer_3d.points.clear()
	line_renderer_3d.points.append_array([Vector3.ZERO, Vector3.UP * 0.75])
	

func change_property(property_name: String, new_value: Variant) -> void:
	match property_name:
		LABEL: label = new_value
		DESCRIPTION: description = new_value
		ACTIVE: active = new_value
		RANGE: range_radius = new_value
		COLOR: light_color = new_value


func _process(_delta: float) -> void:
	var ligth = level.get_light(position_2d)
	if ligth != cached_light:
		dirty_light = true
	cached_light = ligth

	if dirty_light:
		update_light()
		dirty_light = false


func update_light():
	hidden = not is_watched


func _set_selected(value: bool) -> void:
	super._set_selected(value)
		
	line_renderer_3d.disabled = not value


func remove():
	super.remove()
	
	if active:
		level.active_lights.erase(self)


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
