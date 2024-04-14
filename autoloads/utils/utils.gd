extends Node
	
	
func v2_to_v3(v2 : Vector2) -> Vector3:
	return Vector3(v2.x, 0, v2.y)


func v3_to_v2(v3 : Vector3) -> Vector2:
	return Vector2(v3.x, v3.z)


func v3_to_v2i(v3 : Vector3) -> Vector2i:
	return Vector2i(floor(v3.x), floor(v3.z))


func v2_to_v2i(v2 : Vector2) -> Vector2i:
	return Vector2i(floor(v2.x), floor(v2.y))


func v3_to_v3i(v3 : Vector3) -> Vector3i:
	return Vector3i(v3.floor())
	
	
func v3_to_str(v3 : Vector3) -> String:
	return "(%s, %s, %s)" % [v3.x, v3.y, v3.z]
	
	
func v3i_to_str(v3i : Vector3i) -> String:
	return "(%s, %s, %s)" % [v3i.x, v3i.y, v3i.z]


func array3_to_v3(array : Array) -> Vector3:
	return Vector3(array[0], array[1], array[2])


func array2_to_v3(array : Array) -> Vector3:
	return Vector3(array[0], 0, array[1])


func array3_to_v3i(array : Array) -> Vector3i:
	return Vector3i(array[0], array[1], array[2])


func v3_to_array3(v3 : Vector3) -> Array:
	return [snappedf(v3.x, 0.001), snappedf(v3.y, 0.001), snappedf(v3.z, 0.001)]


func v3_to_array2(v3 : Vector3) -> Array:
	return [snappedf(v3.x, 0.001), snappedf(v3.z, 0.001)]


func v3i_to_array3(v3i : Vector3) -> Array:
	return [v3i.x, v3i.y, v3i.z]


func color_to_string(color : Color) -> String:
	return color.to_html()
	
	
func string_to_color(string : String) -> Color:
	return Color.html(string)


func safe_connect(disconnect_signal : Signal, callabe : Callable):
	if not disconnect_signal.is_connected(callabe):
		disconnect_signal.connect(callabe)


func safe_disconnect(connect_signal : Signal, callabe : Callable):
	if connect_signal.is_connected(callabe):
		connect_signal.disconnect(callabe)
		

func get_bitmask(x : int) -> int:
	return int(pow(2, x - 1))


func get_mouse_hit(camera : Camera3D, raycast : PhysicsRayQueryParameters3D, collision_mask : int) -> Dictionary:
	var ray_length := 1000.0
	var viewport := camera.get_viewport()
	var mouse_pos := viewport.get_mouse_position()
	if not viewport.get_visible_rect().has_point(mouse_pos):
		return {}

	var space_state := camera.get_world_3d().direct_space_state
	raycast.from = camera.project_ray_origin(mouse_pos)
	raycast.to = raycast.from + camera.project_ray_normal(mouse_pos) * ray_length
	raycast.collision_mask = collision_mask
	return space_state.intersect_ray(raycast)


func loads_json(data : String) -> Dictionary:
	var json := JSON.new()
	json.parse(data)
	var result : Dictionary = json.data
	if result == null:
		printerr("JSON load failed on line %s: %s" % [json.get_error_line(), json.get_error_message()])
		return {}
		
	return result


func load_json(path : String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	var open_error := FileAccess.get_open_error()
	if open_error:
		printerr("error reading json: %s" % error_string(open_error))
		return {}
		
	var text := file.get_as_text()
	var dict := loads_json(text)
	return dict


func dumps_json(data) -> String:
	return JSON.stringify(data, "", false)


func dump_json(path : String, data):
	var json_string := dumps_json(data)
	var file := FileAccess.open(path, FileAccess.WRITE)
	var open_error := FileAccess.get_open_error()
	if open_error:
		printerr("error writing json: %s" % error_string(open_error))
	file.store_line(json_string)


func make_dirs(path : String):
	DirAccess.make_dir_recursive_absolute(path)
