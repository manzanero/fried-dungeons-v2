class_name ImportTexture
extends Control

signal attributes_changed(resource: CampaignResource, attributes: Dictionary)

const DEFAULT_SIZE := [16, 16]
const DEFAULT_FRAMES := 1
const DEFAULT_SLICES := 1
const DEFAULT_THICKNESS := 1.0
const DEFAULT_SCALE := 0.5
const DEFAULT_DIRECTION := "front"

var resource: CampaignResource: set = _set_resource
var attributes: Dictionary : set = _set_attributes, get = _get_attributes
var frame := 0 :
	set(value): frame = value; frame_label.text = str(value)
var frames := 1 :
	set(value): frames = value; frames_label.text = str(value - 1)


@onready var attribute_fields := {
	"size": %SizeField,
	"thickness": %ThicknessField,
	"scale": %ScaleField,
	"frames": %FramesField,
	"slices": %SlicesField,
	"direction": %DirectionField,
}

var texture_index_attribute_fields := {}

@onready var import_as_choice_field: ChoiceField = %ImportAsChoiceField
@onready var sliced_shape_attributes_container: PropertyContainer = %SlicedShapeAttributesContainer
@onready var texture_index_attributes_container: PropertyContainer = %TextureIndexAttributesContainer

@onready var frame_label: Label = %FrameLabel
@onready var frames_label: Label = %FramesLabel
@onready var previous_frame_button: Button = %PreviousFrameButton
@onready var next_frame_button: Button = %NextFrameButton
@onready var slices_parent: Control = %Slices
@onready var reset_button: Button = %ResetButton
@onready var full_texture: TextureRect = %FullTexture


func _set_resource(_resource: CampaignResource) -> void:
	resource = _resource
	if not resource:
		return
	
	attributes = Game.campaign.get_resource_data(resource.path).get("attributes", {})
	_make_preview_image()


func _set_attributes(_attributes: Dictionary) -> void:
	reset_texture()
	if _attributes.has("size"):
		attribute_fields.size.property_value = Utils.a2_to_v2(_attributes.size)
	if _attributes.has("frames"):
		attribute_fields.frames.property_value = _attributes.frames
		frames = _attributes.frames
	if _attributes.has("slices"):
		attribute_fields.slices.property_value = _attributes.slices
	if _attributes.has("thickness"):
		attribute_fields.thickness.property_value = _attributes.thickness
	if _attributes.has("scale"):
		attribute_fields.scale.property_value = _attributes.scale * 100
	if _attributes.has("direction"):
		attribute_fields.direction.property_value = _attributes.direction


func _get_attributes() -> Dictionary:
	return {
		"size": Utils.v2_to_a2(attribute_fields.size.property_value),
		"frames": attribute_fields.frames.property_value,
		"slices": attribute_fields.slices.property_value,
		"thickness": attribute_fields.thickness.property_value,
		"scale": attribute_fields.scale.property_value / 100,
		"direction": attribute_fields.direction.property_value,
	}


func reset_texture() -> void:
	var texture := Utils.png_to_texture(resource.abspath)
	full_texture.texture = texture
	attribute_fields.size.property_value = texture.get_size()
	attribute_fields.frames.property_value = DEFAULT_FRAMES
	attribute_fields.slices.property_value = DEFAULT_SLICES
	attribute_fields.thickness.property_value = DEFAULT_THICKNESS
	attribute_fields.scale.property_value = DEFAULT_SCALE * 100
	attribute_fields.direction.property_value = DEFAULT_DIRECTION
	

func _ready() -> void:
	for attribute_field in attribute_fields.values():
		attribute_field.value_changed.connect(_on_attributes_changed.unbind(2))
			#func _init(_container: String, _hint: String, _params: Dictionary, _value: Variant):
		#container = _container
		#hint = _hint
		#params = _params
		#value = _value
	
	texture_index_attribute_fields = {
		"size": Vector2Field.SCENE.instantiate().init(texture_index_attributes_container,
				"size", Element.Property.new("", Element.Property.Hints.VECTOR_2, {
					"x_suffix": "px",
					"y_suffix": "px",
					"rounded": true,
				}, Vector2.ONE * 16)),
		"textures": IntegerField.SCENE.instantiate().init(texture_index_attributes_container, 
				"textures", Element.Property.new("", Element.Property.Hints.INTEGER, {
					"has_arrows": true,
					"has_slider": false,
					"min_value": 1,
					"max_value": 256,
				}, 1)),
		"variations": IntegerField.SCENE.instantiate().init(texture_index_attributes_container, 
				"variations", Element.Property.new("", Element.Property.Hints.INTEGER, {
					"has_arrows": true,
					"has_slider": false,
					"min_value": 1,
					"max_value": 256,
				}, 1)),
	}
	
	import_as_choice_field.value_changed.connect(_on_import_as_value_changed)
	previous_frame_button.pressed.connect(_on_previous_frame_button_pressed)
	next_frame_button.pressed.connect(_on_next_frame_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)


func _on_attributes_changed() -> void:
	frames = attributes.frames
	frame = clampi(frame, 0, frames - 1)
	_make_preview_image()
	
	attributes_changed.emit(resource, attributes)


func _on_import_as_value_changed(property_name: String, new_value: Variant) -> void:
	var import_as := import_as_choice_field.property_value
	if import_as == "Sliced Shape":
		sliced_shape_attributes_container.visible = true
		texture_index_attributes_container.visible = false
	else:
		sliced_shape_attributes_container.visible = false
		texture_index_attributes_container.visible = true


func _on_previous_frame_button_pressed() -> void:
	if frame == 0: return
	frame -= 1
	_make_preview_image()


func _on_next_frame_button_pressed() -> void:
	if frame + 1 == frames: return
	frame += 1
	_make_preview_image()


func _on_reset_button_pressed() -> void:
	reset_texture()
	attributes_changed.emit(resource, attributes)


func _make_preview_image():
	var time := Utils.get_time()
	for slice in slices_parent.get_children():
		slice.queue_free()
	
	var atlas_texture := Utils.png_to_atlas(resource.abspath)
	
	var cached_attributes = attributes
	frames = cached_attributes.frames
	frame = clampi(frame, 0, frames - 1)
	
	var tex_size := Utils.a2_to_v2(cached_attributes.size)
	for i in range(cached_attributes.slices):
		var slice_texture := atlas_texture.duplicate()
		slice_texture.region = Rect2(tex_size.x * frame, tex_size.y * i, tex_size.x, tex_size.y)
		var slice := TextureRect.new()
		slice.texture = slice_texture
		slice.set_anchors_preset(Control.PRESET_FULL_RECT)
		slice.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slice.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slices_parent.add_child(slice)
		Debug.print_debug_message("Preview Slice %s created" % i)
	
	var total_time := Utils.get_elapsed_time(time)
	Debug.print_debug_message("Preview Texture loaded in %s seconds" % total_time)
