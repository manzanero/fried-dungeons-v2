class_name ImportTexture
extends Control

signal attributes_changed(resource: CampaignResource, import_as: String, attributes: Dictionary)

const SLICED_SHAPE_DEFAULTS := {
	"size": [16, 16],
	"thickness": 1,
	"slices": 1,
	"frames": 1,
	"scale": 1,
	"direction": "front",
}

const TEXTURE_INDEX_DEFAULTS := {
	"size": [16, 16],
	"textures": 1,
	"frames": 1,
}

var resource: CampaignResource: set = _set_resource
var import_as: String = CampaignResource.TEXTURE_IMPORTS[0]
var attributes: Dictionary : set = _set_attributes, get = _get_attributes
var texture_index_preview := 0
var textures := 1 :
	set(value): textures = value; textures_label.text = str(value - 1)
var frame := 0 :
	set(value): frame = value; frame_label.text = str(value)
var frames := 1 :
	set(value): frames = value; frames_label.text = str(value - 1)

var sliced_shape_attribute_fields := {}
var texture_index_attribute_fields := {}

@onready var import_as_choice_field: ChoiceField = %ImportAsChoiceField
@onready var sliced_shape_attributes_container: PropertyContainer = %SlicedShapeAttributesContainer
@onready var texture_index_attributes_container: PropertyContainer = %TextureIndexAttributesContainer

@onready var texture_panel: PanelContainer = %TexturePanel
@onready var texture_label: LineEdit = %TextureLabel
@onready var textures_label: Label = %TotalTexturesLabel
@onready var previous_texture_button: Button = %PreviousTextureButton
@onready var next_texture_button: Button = %NextTextureButton

@onready var frame_panel: PanelContainer = %FramePanel
@onready var frame_label: Label = %FrameLabel
@onready var frames_label: Label = %TotalFramesLabel
@onready var previous_frame_button: Button = %PreviousFrameButton
@onready var next_frame_button: Button = %NextFrameButton

@onready var slices_parent: Control = %Slices
@onready var reset_button: Button = %ResetButton
@onready var full_texture: TextureRect = %FullTexture


func _set_resource(_resource: CampaignResource) -> void:
	resource = _resource
	if not resource:
		return
	
	var resource_data: Dictionary = Game.campaign.get_resource_data(resource.path)
	import_as = resource_data.get("import_as", {})
	import_as_choice_field.set_value(import_as)
	_on_import_as_value_changed(false)
	attributes = resource_data.get("attributes", {})
	_make_preview_image()


func _set_attributes(_attributes: Dictionary) -> void:
	reset_texture()
	
	match import_as:
		CampaignResource.ImportAs.SLICED_SHAPE:
			if _attributes.has("size"):
				sliced_shape_attribute_fields.size.set_value(Utils.a2_to_v2(_attributes.size))
			if _attributes.has("slices"):
				sliced_shape_attribute_fields.slices.set_value(_attributes.slices)
			if _attributes.has("frames"):
				sliced_shape_attribute_fields.frames.set_value(_attributes.frames)
				frames = _attributes.frames
			if _attributes.has("thickness"):
				sliced_shape_attribute_fields.thickness.set_value(_attributes.thickness)
			if _attributes.has("scale"):
				sliced_shape_attribute_fields.scale.set_value(_attributes.scale * 100.0)
			if _attributes.has("direction"):
				sliced_shape_attribute_fields.direction.set_value(_attributes.direction)
		CampaignResource.ImportAs.TEXTURE_INDEX:
			if _attributes.has("size"):
				texture_index_attribute_fields.size.set_value(Utils.a2_to_v2(_attributes.size))
			if _attributes.has("textures"):
				texture_index_attribute_fields.textures.set_value(_attributes.textures)
				textures = _attributes.textures
			if _attributes.has("frames"):
				texture_index_attribute_fields.frames.set_value(_attributes.frames)
				frames = _attributes.frames


func _get_attributes() -> Dictionary:
	var _attributes := {}
	match import_as:
		CampaignResource.ImportAs.SLICED_SHAPE:
			_attributes = {
				"size": Utils.v2_to_a2(sliced_shape_attribute_fields.size.property_value),
				"frames": sliced_shape_attribute_fields.frames.property_value,
				"slices": sliced_shape_attribute_fields.slices.property_value,
				"thickness": sliced_shape_attribute_fields.thickness.property_value,
				"scale": sliced_shape_attribute_fields.scale.property_value / 100.0,
				"direction": sliced_shape_attribute_fields.direction.property_value,
			}
		CampaignResource.ImportAs.TEXTURE_INDEX:
			_attributes = {
				"size": Utils.v2_to_a2(texture_index_attribute_fields.size.property_value),
				"textures": texture_index_attribute_fields.textures.property_value,
				"frames": texture_index_attribute_fields.frames.property_value,
			}
	return _attributes


func reset_texture() -> void:
	texture_index_preview = 0
	frame = 0
	match import_as:
		CampaignResource.ImportAs.SLICED_SHAPE:
			var texture := Utils.png_to_texture(resource.abspath)
			full_texture.texture = texture
			sliced_shape_attribute_fields.size.set_value(texture.get_size())
			sliced_shape_attribute_fields.slices.set_value(SLICED_SHAPE_DEFAULTS.slices)
			sliced_shape_attribute_fields.frames.set_value(SLICED_SHAPE_DEFAULTS.frames)
			sliced_shape_attribute_fields.thickness.set_value(SLICED_SHAPE_DEFAULTS.thickness)
			sliced_shape_attribute_fields.scale.set_value(SLICED_SHAPE_DEFAULTS.scale * 100.0)
			sliced_shape_attribute_fields.direction.set_value(SLICED_SHAPE_DEFAULTS.direction)
		CampaignResource.ImportAs.TEXTURE_INDEX:
			var texture := Utils.png_to_texture(resource.abspath)
			full_texture.texture = texture
			var _texture_size = Utils.a2_to_v2(TEXTURE_INDEX_DEFAULTS.size)
			var _full_texture_size = texture.get_size()
			texture_index_attribute_fields.size.set_value(_texture_size)
			texture_index_attribute_fields.textures.set_value(_full_texture_size.y / _texture_size.y)
			texture_index_attribute_fields.frames.set_value(_full_texture_size.x / _texture_size.x)
	

func _ready() -> void:
	sliced_shape_attribute_fields = {
		"size": Vector2Field.SCENE.instantiate().init(
			sliced_shape_attributes_container, "size", 
			Element.Property.new("", Element.Hint.VECTOR_2, {
				"x_suffix": "px",
				"y_suffix": "px",
				"rounded": true,
				"x_min_value": 1,
				"y_min_value": 1,
				"allow_greater": true,
				"allow_lesser": false,
			}, Vector2.ONE)
		),
		"thickness": IntegerField.SCENE.instantiate().init(
			sliced_shape_attributes_container, "thickness", 
			Element.Property.new("", Element.Hint.INTEGER, {
				"suffix": "px",
				"has_arrows": true,
				"has_slider": false,
				"step": 1,
				"min_value": 1,
				"max_value": 256,
			}, 1)
		),
		"scale": IntegerField.SCENE.instantiate().init(
			sliced_shape_attributes_container, "scale", 
			Element.Property.new("", Element.Hint.INTEGER, {
				"suffix": "%",
				"has_arrows": true,
				"has_slider": true,
				"step": 5,
				"min_value": 1,
				"max_value": 200,
				"allow_lesser": false,
				"allow_greater": true,
			}, 50)
		),
		"frames": IntegerField.SCENE.instantiate().init(
			sliced_shape_attributes_container, "frames",
			Element.Property.new("", Element.Hint.INTEGER, {
				"has_arrows": true,
				"has_slider": false,
				"step": 1,
				"min_value": 1,
				"max_value": 256,
			}, 1)
		),
		"slices": IntegerField.SCENE.instantiate().init(
			sliced_shape_attributes_container, "slices",
			Element.Property.new("", Element.Hint.INTEGER, {
				"has_arrows": true,
				"has_slider": false,
				"step": 1,
				"min_value": 1,
				"max_value": 256,
			}, 1)
		),
		"direction": ChoiceField.SCENE.instantiate().init(
			sliced_shape_attributes_container, "direction",
			Element.Property.new("", Element.Hint.INTEGER, {
				"choices": [
					["front", "Front"],
					["top", "Top"],
					["side", "Side"],
				],
			}, "front")),
	}
	for attribute_field in sliced_shape_attribute_fields.values():
		attribute_field.value_changed.connect(_on_attributes_changed.unbind(2))
	
	texture_index_attribute_fields = {
		"size": Vector2Field.SCENE.instantiate().init(
			texture_index_attributes_container, "size", 
			Element.Property.new("", Element.Hint.VECTOR_2, {
				"x_suffix": "px",
				"y_suffix": "px",
				"rounded": true,
			}, Vector2.ONE * 16)
		),
		"textures": IntegerField.SCENE.instantiate().init(
			texture_index_attributes_container, "textures",
			Element.Property.new("", Element.Hint.INTEGER, {
				"has_arrows": true,
				"has_slider": false,
				"min_value": 1,
				"max_value": 256,
			}, 1)
		),
		"frames": IntegerField.SCENE.instantiate().init(
			texture_index_attributes_container, "frames",
			Element.Property.new("", Element.Hint.INTEGER, {
				"has_arrows": true,
				"has_slider": false,
				"min_value": 1,
				"max_value": 256,
			}, 1)
		),
	}
	for attribute_field in texture_index_attribute_fields.values():
		attribute_field.value_changed.connect(_on_attributes_changed.unbind(2))
	
	import_as_choice_field.value_changed.connect(_on_import_as_value_changed.unbind(2))
	texture_label.text_changed.connect(_on_texture_text_changed)
	previous_texture_button.pressed.connect(_on_previous_texture_button_pressed)
	next_texture_button.pressed.connect(_on_next_texture_button_pressed)
	previous_frame_button.pressed.connect(_on_previous_frame_button_pressed)
	next_frame_button.pressed.connect(_on_next_frame_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)


func _on_attributes_changed() -> void:
	var _attributes = attributes
	frames = attributes.frames
	frame = clampi(frame, 0, frames - 1)
	_make_preview_image()
	
	attributes_changed.emit(resource, import_as, _attributes)


func _on_import_as_value_changed(save_resource := true) -> void:
	import_as = import_as_choice_field.get_value()
	if import_as == CampaignResource.ImportAs.SLICED_SHAPE:
		sliced_shape_attributes_container.visible = true
		texture_index_attributes_container.visible = false
		texture_panel.visible = false
	else:
		sliced_shape_attributes_container.visible = false
		texture_index_attributes_container.visible = true
		texture_panel.visible = true
		
	if save_resource:
		attributes_changed.emit(resource, import_as, attributes)
		

func _on_texture_text_changed(new_text: String) -> void:
	if new_text.is_valid_int():
		texture_index_preview = new_text.to_int()
		_make_preview_image()

func _on_previous_texture_button_pressed() -> void:
	texture_index_preview -= 1
	if texture_index_preview <= -1: 
		texture_index_preview = textures - 1
	texture_label.text = str(texture_index_preview)
	_make_preview_image()

func _on_next_texture_button_pressed() -> void:
	texture_index_preview += 1
	if texture_index_preview >= textures: 
		texture_index_preview = 0
	texture_label.text = str(texture_index_preview)
	_make_preview_image()
			

func _on_previous_frame_button_pressed() -> void:
	frame -= 1
	if frame <= -1: 
		frame = frames - 1
	_make_preview_image()

func _on_next_frame_button_pressed() -> void:
	frame += 1
	if frame >= frames: 
		frame = 0
	_make_preview_image()

func _on_reset_button_pressed() -> void:
	reset_texture()
	_make_preview_image()
	attributes_changed.emit(resource, import_as, attributes)


func _make_preview_image():
	var time := Utils.get_time()
	
	for slice in slices_parent.get_children():
		slice.queue_free()
	
	var atlas_texture := Utils.png_to_atlas(resource.abspath)
	
	var _attributes = attributes
	frames = _attributes.frames
	frame = clampi(frame, 0, frames - 1)
	var tex_size := Utils.a2_to_v2(_attributes.size)
	
	match import_as:
		CampaignResource.ImportAs.SLICED_SHAPE:
			for i in range(_attributes.slices):
				var slice_texture := atlas_texture.duplicate()
				slice_texture.region = Rect2(tex_size.x * frame, tex_size.y * i, tex_size.x, tex_size.y)
				var slice := TextureRect.new()
				slice.texture = slice_texture
				slice.set_anchors_preset(Control.PRESET_FULL_RECT)
				slice.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				slice.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				slices_parent.add_child(slice)
				Debug.print_debug_message("Preview Slice %s created" % i)
		CampaignResource.ImportAs.TEXTURE_INDEX:
			textures = _attributes.textures
			texture_index_preview = clampi(texture_index_preview, 0, textures - 1)
			
			var slice_texture := atlas_texture.duplicate()
			slice_texture.region = Rect2(tex_size.x * frame, tex_size.y * texture_index_preview, tex_size.x, tex_size.y)
			var slice := TextureRect.new()
			slice.texture = slice_texture
			slice.set_anchors_preset(Control.PRESET_FULL_RECT)
			slice.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			slice.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			slices_parent.add_child(slice)
			Debug.print_debug_message("Preview Texture %s created" % texture_index_preview)
	
	var total_time := Utils.get_elapsed_time(time)
	Debug.print_debug_message("Preview Texture loaded in %s seconds" % total_time)
