class_name DroppableTextureButton
extends Button


signal dropped_texture(texture: CampaignResource)


func _can_drop_data(_at_position: Vector2, drop_data: Variant) -> bool:
	if not drop_data is Dictionary:
		return false
	if drop_data.get("type") != "campaign_resouce_items":
		return false
	if not drop_data.get("items"):
		return false
	return true


func _drop_data(_at_position: Vector2, drop_data: Variant) -> void:
	var resource_item: TreeItem = drop_data.items[0]
	var resource: CampaignResource = resource_item.get_metadata(0)
	if resource.resource_type != CampaignResource.Type.TEXTURE:
		Utils.temp_error_tooltip("Drop Texture", 2, true)
		return
		
	dropped_texture.emit(resource)
