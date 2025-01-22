class_name TabBuilder
extends Control


static var SCENE = preload("res://ui/tabs/tab_builder/tab_builder.tscn")


var material_index_selected := 5 :
	set(value):
		material_index_selected = value
		var texture_button: AtlasTextureButton = material_buttons_parent.get_child(value)
		texture_button.button_pressed = true

@export var material_buttons_parent: Control


func set_atlas_texture_index(atlas_texture: Texture2D, texture_attributes: Dictionary):
	for child in material_buttons_parent.get_children():
		child.queue_free()
	
	var textures_size: Vector2 = Utils.a2_to_v2(texture_attributes.size)
	var textures_count: int = texture_attributes.textures
	
	for i in range(textures_count):
		var texture_button: AtlasTextureButton = AtlasTextureButton.SCENE.instantiate().init(material_buttons_parent, i)
		var button_texture: AtlasTexture = texture_button.texture_rect.texture
		button_texture.atlas = atlas_texture
		button_texture.region = Rect2(0, i * textures_size.y, textures_size.x, textures_size.y)
		texture_button.index_pressed.connect(func (index): material_index_selected = index)
		if material_index_selected == i:
			texture_button.button_pressed = true


func reset():
	var map: Map = Game.ui.selected_map
	if map:
		
		# default atlas texture
		var texture_attributes: Dictionary = Game.DEFAULT_INDEX_TEXTURE_ATTRS
		if map.atlas_texture_resource:
			texture_attributes = map.atlas_texture_resource.attributes
		set_atlas_texture_index(map.atlas_texture, texture_attributes)
		
		# update walls
		RenderingServer.global_shader_parameter_set("wall_atlas", map.atlas_texture)
		
		# updatde ground
		var level := map.selected_level
		if level:
			level.floor_2d.tile_map.tile_set.get_source(0).texture = map.atlas_texture
