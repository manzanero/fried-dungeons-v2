class_name VideoPreferencesWindow
extends FriedWindow


signal video_prefernces_changed

static var element_label_settings := preload("res://resources/themes/main/element_label_settings.tres")


var visible_camera_pivot: bool :
	set(value): visible_camera_pivot_field.property_value = value; _on_video_preferences_changed()
	get: return visible_camera_pivot_field.property_value
var mouse_sensibility: float :
	set(value): mouse_sensibility_field.property_value = value * 100; _on_video_preferences_changed()
	get: return mouse_sensibility_field.property_value / 100
var label_size: float :
	set(value): label_size_field.property_value = value * 100; _on_video_preferences_changed()
	get: return label_size_field.property_value / 100
var crt_filter: bool :
	set(value): crt_filter_field.property_value = value; _on_video_preferences_changed()
	get: return crt_filter_field.property_value
var low_quality_shadows: bool :
	set(value): low_quality_shadows_field.property_value = value; _on_video_preferences_changed()
	get: return low_quality_shadows_field.property_value


@onready var visible_camera_pivot_field: BoolField = %VisibleCameraPivot
@onready var mouse_sensibility_field: FloatField = %MouseSensibility
@onready var label_size_field: FloatField = %LabelSize
@onready var crt_filter_field: BoolField = %CRTFilter
@onready var low_quality_shadows_field: BoolField = %LowQualityShadows



func _ready() -> void:
	super._ready()
	Game.video_preferences = self
	read_preferences()
	visible_camera_pivot_field.value_changed.connect(_on_visible_camera_pivot_changed.unbind(2))
	visible_camera_pivot_field.value_changed.connect(_on_video_preferences_changed.unbind(2))
	mouse_sensibility_field.value_changed.connect(_on_mouse_sensibility_changed.unbind(2))
	mouse_sensibility_field.value_changed.connect(_on_video_preferences_changed.unbind(2))
	label_size_field.value_changed.connect(_on_label_size_changed.unbind(2))
	label_size_field.value_changed.connect(_on_video_preferences_changed.unbind(2))
	crt_filter_field.value_changed.connect(_on_crt_filter_changed.unbind(2))
	crt_filter_field.value_changed.connect(_on_video_preferences_changed.unbind(2))
	low_quality_shadows_field.value_changed.connect(_on_low_quality_shadows_changed.unbind(2))
	low_quality_shadows_field.value_changed.connect(_on_video_preferences_changed.unbind(2))
	visibility_changed.connect(_on_visibility_changed)
	

func _on_visibility_changed() -> void:
	if visible:
		Game.ui.mouse_blocker.visible = true


func _on_visible_camera_pivot_changed():
	Camera.show_focus_point = visible_camera_pivot

func _on_mouse_sensibility_changed() -> void:
	Camera.mouse_sensibility = mouse_sensibility

func _on_label_size_changed() -> void:
	element_label_settings.font_size = get_font_size()
	for map: Map in Game.maps.values():
		for level: Level in map.levels.values():
			for element: Element in level.elements.values():
				if element is Entity:
					element.label_label.label_settings.font_size = get_font_size()
				elif element is Prop:
					element.label_label.label_settings.font_size = get_font_size()

func get_font_size():
	return label_size * 24


func _on_crt_filter_changed() -> void:
	Game.ui.selected_scene_tab.crt.visible = crt_filter


func _on_low_quality_shadows_changed() -> void:
	for i in Game.ui.scene_tabs.get_tab_count():
		var scene_tab: TabScene = Game.ui.scene_tabs.get_tab_control(i)
		scene_tab.sub_viewport.positional_shadow_atlas_size = get_positional_shadow_atlas_size()

func get_positional_shadow_atlas_size():
	return 1024 if low_quality_shadows else 8192
	

var scheduled_save := false

func _on_video_preferences_changed() -> void:
	video_prefernces_changed.emit()
	
	if scheduled_save:
		return
	
	scheduled_save = true
	get_tree().create_timer(1).timeout.connect(func ():
		scheduled_save = false
		save()
	)


func save():
	Utils.dump_json("user://preferences/video.json", {
		"visible_camera_pivot": visible_camera_pivot,
		"mouse_sensibility": mouse_sensibility,
		"label_size": label_size,
		"crt_filter": crt_filter,
		"low_quality_shadows": low_quality_shadows,
	}, 2)
	
	
func read_preferences():
	var video_preferences = Utils.load_json("user://preferences/video.json")
	visible_camera_pivot = video_preferences.get("visible_camera_pivot", true)
	mouse_sensibility = video_preferences.get("mouse_sensibility", 0.5)
	label_size = video_preferences.get("label_size", 0.25)
	crt_filter = video_preferences.get("crt_filter", true) 
	low_quality_shadows = video_preferences.get("low_quality_shadows", false)
