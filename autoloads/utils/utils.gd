extends Node
	
	
func v2_to_v3(v2 : Vector2) -> Vector3:
	return Vector3(v2.x, 0, v2.y)


func v3_to_v2(v3 : Vector3) -> Vector2:
	return Vector2(v3.x, v3.z)


func v3_to_v2i(v3 : Vector3) -> Vector2i:
	return Vector2i(floori(v3.x), floori(v3.z))


func v2_to_v2i(v2 : Vector2) -> Vector2i:
	return Vector2i(floori(v2.x), floori(v2.y))


func v3_to_v3i(v3 : Vector3) -> Vector3i:
	return Vector3i(v3.floor())
	
	
func v3_to_str(v3 : Vector3) -> String:
	return "(%s, %s, %s)" % [v3.x, v3.y, v3.z]
	
	
func v3i_to_str(v3i : Vector3i) -> String:
	return "(%s, %s, %s)" % [v3i.x, v3i.y, v3i.z]


func a3_to_v3(array : Array) -> Vector3:
	return Vector3(array[0], array[1], array[2])


func a2_to_v3(array : Array) -> Vector3:
	return Vector3(array[0], 0, array[1])


func a2_to_v2(array : Array) -> Vector2:
	return Vector2(array[0], array[1])


func a3_to_v3i(array : Array[float]) -> Vector3i:
	return Vector3i(floori(array[0]), floori(array[1]), floori(array[2]))


func v3_to_a3(v3 : Vector3) -> Array[float]:
	return [snappedf(v3.x, 0.001), snappedf(v3.y, 0.001), snappedf(v3.z, 0.001)]


func v3_to_a2(v3: Vector3) -> Array[float]:
	return [snappedf(v3.x, 0.001), snappedf(v3.z, 0.001)]


func v3i_to_a3i(v3i: Vector3i) -> Array[int]:
	return [v3i.x, v3i.y, v3i.z]
	

func aa2_to_pv2(array: Array) -> PackedVector2Array:
	var pv2: PackedVector2Array = []
	for item in array:
		pv2.append(a2_to_v2(item))
	return pv2
	

func aa2_to_tpv2(array: Array) -> PackedVector2Array:
	var pv2: PackedVector2Array = []
	for item in array:
		pv2.append(a2_to_v2([item[1], item[0]]))
	pv2.reverse()
	return pv2
	

func aaa2_to_apv2(array: Array) -> Array[PackedVector2Array]:
	var apv2: Array[PackedVector2Array] = []
	for item in array:
		apv2.append(aa2_to_pv2(item))
	return apv2
	

func aaa2_to_atpv2(array: Array) -> Array[PackedVector2Array]:
	var apv2: Array[PackedVector2Array] = []
	for item in array:
		apv2.append(aa2_to_tpv2(item))
	return apv2


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


func get_hit(from : Node3D, to_point : Vector3, raycast : PhysicsRayQueryParameters3D, collision_mask : int) -> Dictionary:
	var space_state := from.get_world_3d().direct_space_state
	raycast.from = from.global_position
	raycast.to = to_point
	raycast.collision_mask = collision_mask
	return space_state.intersect_ray(raycast)


func get_mouse_hit(camera : Camera3D, from_center : bool, raycast : PhysicsRayQueryParameters3D, collision_mask : int) -> Dictionary:
	var ray_length := 1000.0
	var space_state := camera.get_world_3d().direct_space_state
	
	if from_center:
		raycast.from = camera.global_position
		raycast.to = -camera.global_basis.z * ray_length
			
	else:
		var viewport := camera.get_viewport()
		var mouse_pos := viewport.get_mouse_position()
		if not viewport.get_visible_rect().has_point(mouse_pos):
			return {}
			
		raycast.from = camera.project_ray_origin(mouse_pos)
		raycast.to = raycast.from + camera.project_ray_normal(mouse_pos) * ray_length
		
	raycast.collision_mask = collision_mask
	#raycast.hit_back_faces = false
	return space_state.intersect_ray(raycast)


func loads_json(data : String) -> Dictionary:
	var json := JSON.new()
	json.parse(data)
	var result := json.data as Dictionary
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


func dump_json(path : String, data : Dictionary) -> void:
	var json_string := dumps_json(data)
	var file := FileAccess.open(path, FileAccess.WRITE)
	var open_error := FileAccess.get_open_error()
	if open_error:
		printerr("error writing json: %s" % error_string(open_error))
	file.store_line(json_string)


func make_dirs(path : String) -> void:
	DirAccess.make_dir_recursive_absolute(path)
