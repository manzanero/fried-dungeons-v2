class_name ImportTexture
extends Control

signal resource_changed(resource)

const DEFAULT_SIZE := [16, 16]
const DEFAULT_FRAMES := 1
const DEFAULT_SLICES := 1
const DEFAULT_DEPTH := 1.0
const DEFAULT_SCALE := 0.5
const DEFAULT_TILTED := false

var resource: CampaignResource: set = _set_resource
var import_data: Dictionary : set = _set_import_data, get = _get_import_data
var frame := 0 :
	set(value): frame = value; frame_label.text = str(value)
var frames := 1 :
	set(value): frames = value; frames_label.text = str(value - 1)


@onready var import_fields := {
	"size": %SizeField,
	"frames": %FramesField,
	"slices": %SlicesField,
	"depth": %DepthField,
	"scale": %ScaleField,
	"tilted": %TiltedField,
}

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
	
	import_data = Game.campaign.imports.get(resource.path, {})
	_make_preview_image()


func _set_import_data(_import_data: Dictionary) -> void:
	reset()
	if _import_data.get("size"):
		import_fields.size.property_value = Utils.a2_to_v2(_import_data.size)
	if _import_data.get("frames"):
		import_fields.frames.property_value = _import_data.frames
		frames = _import_data.frames
	if _import_data.get("slices"):
		import_fields.slices.property_value = _import_data.slices
	if _import_data.get("depth"):
		import_fields.depth.property_value = _import_data.depth
	if _import_data.get("scale"):
		import_fields.scale.property_value = _import_data.scale
	if _import_data.get("tilted"):
		import_fields.tilted.property_value = _import_data.tilted


func _get_import_data() -> Dictionary:
	return {
		"size": Utils.v2_to_a2(import_fields.size.property_value),
		"frames": import_fields.frames.property_value,
		"slices": import_fields.slices.property_value,
		"depth": import_fields.depth.property_value,
		"scale": import_fields.scale.property_value,
		"tilted": import_fields.tilted.property_value,
	}


func reset() -> void:
	var texture := Utils.png_to_texture(resource.abspath)
	full_texture.texture = texture
	import_fields.size.property_value = texture.get_size()
	import_fields.frames.property_value = 1
	import_fields.slices.property_value = 1
	import_fields.depth.property_value = 1
	import_fields.scale.property_value = 0.5
	import_fields.tilted.property_value = false
	

func _ready() -> void:
	for import_field in import_fields.values():
		import_field.value_changed.connect(_on_import_data_changed.unbind(2))
	
	previous_frame_button.pressed.connect(_on_previous_frame_button_pressed)
	next_frame_button.pressed.connect(_on_next_frame_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)


func _on_import_data_changed() -> void:
	resource.import_data = import_data
	resource_changed.emit(resource)
	resource.resource_changed.emit()
	frames = resource.import_data.frames
	frame = clampi(frame, 0, frames - 1)
	_make_preview_image()
	
	Game.server.rpcs.change_resource_import_data.rpc(CampaignResource.Type.TEXTURE, resource.path, import_data)


func _on_previous_frame_button_pressed() -> void:
	if frame == 0: return
	frame -= 1
	_make_preview_image()


func _on_next_frame_button_pressed() -> void:
	if frame + 1 == frames: return
	frame += 1
	_make_preview_image()


func _on_reset_button_pressed() -> void:
	reset()
	Game.campaign.imports.erase(resource.path)


func _make_preview_image():
	var time := Utils.get_time()
	for slice in slices_parent.get_children():
		slice.queue_free()
	
	var atlas_texture := Utils.png_to_atlas(resource.abspath)
	
	var cached_import_data = import_data
	frames = cached_import_data.frames
	frame = clampi(frame, 0, frames - 1)
	
	var tex_size := Utils.a2_to_v2(cached_import_data.size)
	for i in range(cached_import_data.slices):
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
