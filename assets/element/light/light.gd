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
		_refresh_mesh()
		
		## This is not needed now
		#if active:
			#level.active_lights.append(self)
			#
			## Only a certain number of lights can be active at a time
			#if level.active_lights.size() > Game.MAX_LIGHTS:
				#Debug.print_message(Debug.ERROR, "Max. lights exceeded")
				#var first_light: Light = level.active_lights.pop_front()
				#first_light.active = false
				#
		#else:
			#level.active_lights.erase(self)

var light_color := Color.WHITE :
	set(value):
		light_color = value
		color = value
		omni_light_3d.light_color = value
		_refresh_mesh()
		

var hidden := true :
	set(value): hidden = value; _refresh_mesh()


func _refresh_mesh():
	if active:
		if hidden:
			inner_material.set_shader_parameter("base_color", color)
			inner_material.set_shader_parameter("inside_color", Color.LIGHT_GRAY)
			inner_material.set_shader_parameter("use_dither", true)
		else:
			inner_material.set_shader_parameter("base_color", color)
			inner_material.set_shader_parameter("inside_color", Color.LIGHT_GRAY)
			inner_material.set_shader_parameter("use_dither", false)
	else:
		if hidden:
			inner_material.set_shader_parameter("base_color", color)
			inner_material.set_shader_parameter("inside_color", Color.LIGHT_GRAY)
			inner_material.set_shader_parameter("use_dither", true)
		else:
			inner_material.set_shader_parameter("base_color", color)
			inner_material.set_shader_parameter("inside_color", Color.LIGHT_GRAY)
			inner_material.set_shader_parameter("use_dither", false)
	
	update_light()
	

var dirty_light := false
var dirty_mesh := false
var selector_disabled := false : set = _set_selector_disabled


@onready var omni_light_3d := $OmniLight3D as OmniLight3D
@onready var body = $Body as Node3D
@onready var inner_mesh := %InnerMesh as MeshInstance3D
@onready var inner_material := inner_mesh.get_surface_override_material(0) as ShaderMaterial
@onready var outer_mesh := %OuterMesh as MeshInstance3D
@onready var outer_material := outer_mesh.get_surface_override_material(0) as StandardMaterial3D
@onready var selector_collider: StaticBody3D = %SelectorCollider
@onready var line_renderer_3d := %LineRenderer3D as LineRenderer


## properties
const LABEL := "label"
const COLOR = "color"
const DESCRIPTION := "description"
const BLUEPRINT := "blueprint"
const ACTIVE = "active"
const RANGE = "range"
const HIDDEN = "hidden"

const light_init_properties = {
	LABEL: {
		"container": "",
		"hint": Hint.STRING,
		"params": {},
		"default": "Light Unknown",
	},
	DESCRIPTION: {
		"container": "",
		"hint": Hint.STRING,
		"params": {},
		"default": "",
	},
	COLOR: {
		"container": "",
		"hint": Hint.COLOR,
		"params": {},
		"default": Color.WHITE,
	},
	BLUEPRINT: {
		"container": "",
		"hint": Hint.BLUEPRINT,
		"params": {},
		"default": null,
	},
	ACTIVE: {
		"container": "light",
		"hint": Hint.BOOL,
		"params": {},
		"default": true,
	},
	RANGE: {
		"container": "light",
		"hint": Hint.FLOAT,
		"params":  {
			"suffix": "u",
			"has_slider": true,
			"has_arrows": true,
			"min_value": 1,
			"max_value": 10,
			"step": 1,
		},
		"default": 5,
	},
	HIDDEN: {
		"container": "graphics",
		"hint": Hint.BOOL,
		"params": {},
		"default": true,
	},
}

func _ready() -> void:
	type = "light"
	init_properties = light_init_properties
	
	is_ceiling_element = true
	element_velocity = 10
	
	cached_light = level.get_light(position_2d)
	level.light_texture_updated.connect(_on_light_texture_updated)
	Game.ui.tab_players.control_changed.connect(update_light)
	
	line_renderer_3d.disabled = true
	line_renderer_3d.points.clear()
	line_renderer_3d.points.append_array([Vector3.ZERO, Vector3.UP * 0.75])


static func parse_property_values(property_values: Dictionary) -> Dictionary:
	var raw_property_values := {}
	for property_name in property_values:
		if not light_init_properties.has(property_name):  # to keep compatibility
			continue
		var property_value: Variant = property_values[property_name]
		var init_property_data: Dictionary = light_init_properties[property_name]
		raw_property_values[property_name] = get_raw_property(init_property_data.hint, property_value)
	return raw_property_values


static func parse_raw_property_values(raw_property_values: Dictionary) -> Dictionary:
	var property_values := {}
	for property_name in raw_property_values:
		if not light_init_properties.has(property_name):  # to keep compatibility
			continue
		var raw_property_value: Variant = raw_property_values[property_name]
		var init_property_data: Dictionary = light_init_properties[property_name]
		property_values[property_name] = set_raw_property(init_property_data.hint, raw_property_value)
	return property_values
	

func change_property(property_name: String, new_value: Variant) -> void:
	match property_name:
		LABEL: label = new_value
		DESCRIPTION: description = new_value
		COLOR: light_color = new_value
		BLUEPRINT: _set_blueprint(new_value)
		ACTIVE: active = new_value
		RANGE: range_radius = new_value
		HIDDEN: hidden = new_value


func _on_light_texture_updated():
	var ligth := level.get_light(position_2d)
	if ligth != cached_light:
		cached_light = ligth
		update_light()


func update_light():
	if Game.master_is_player:
		body.visible = is_watched and not hidden and active
	else:
		body.visible = true
		

func _set_selector_disabled(value: bool) -> void:
	selector_collider.get_child(0).disabled = value
		

func _set_selectable(value: bool) -> void:
	super._set_selectable(value)
		
	selector_collider.set_collision_layer_value(Game.SELECTOR_LAYER, value)


func _set_selected(value: bool) -> void:
	super._set_selected(value)
		
	line_renderer_3d.disabled = not value


func remove():
	super.remove()
	
	if active:
		level.active_lights.erase(self)


#region Serializing

func json():
	var values := {}
	for property in properties:
		values[property] = properties[property].get_raw()
		
	return {
		"type": type,
		"id": id,
		"position": Utils.v3_to_a2(global_position),
		"rotation": snappedf(rotation_y, 0.001),
		"properties": values,
	}


#endregion
