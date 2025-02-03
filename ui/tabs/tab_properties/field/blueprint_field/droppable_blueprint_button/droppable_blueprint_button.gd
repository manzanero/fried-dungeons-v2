class_name DroppableBlueprintButton
extends Button


var blueprint_type: String


signal dropped_blueprint(texture: CampaignBlueprint)


func _can_drop_data(_at_position: Vector2, drop_data: Variant) -> bool:
	if not drop_data is Dictionary:
		return false
	if drop_data.get("type") != "campaign_blueprint_items":
		return false
	if not drop_data.get("items"):
		return false
	return true


func _drop_data(_at_position: Vector2, drop_data: Variant) -> void:
	var blueprint_item: TreeItem = drop_data.items[0]
	var blueprint: CampaignBlueprint = blueprint_item.get_metadata(0)
	if blueprint.type != Game.ui.tab_properties.element_selected.type:
		Utils.temp_error_tooltip("Drop %s" % blueprint.type.capitalize(), 2, true)
		return
	dropped_blueprint.emit(blueprint)
