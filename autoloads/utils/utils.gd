extends Node
	
	
func v2_to_v3(v2: Vector2) -> Vector3:
	return Vector3(v2.x, 0, v2.y)
	
	
func v2i_to_v3(v2i: Vector2i) -> Vector3:
	return Vector3(v2i.x, 0, v2i.y)


func v3_to_v2(v3: Vector3) -> Vector2:
	return Vector2(v3.x, v3.z)


func v3_to_v2i(v3: Vector3) -> Vector2i:
	return Vector2i(floori(v3.x), floori(v3.z))


func v2_to_v2i(v2: Vector2) -> Vector2i:
	return Vector2i(floori(v2.x), floori(v2.y))


func v3_to_v3i(v3: Vector3) -> Vector3i:
	return Vector3i(floori(v3.x), floori(v3.y), floori(v3.z))


func v3i_to_html_color(v3i: Vector3i) -> String:
	return Color8(clampi(v3i.x, 0, 255), clampi(v3i.y, 0, 255), clampi(v3i.z, 0, 255)).to_html(false)
	
	
func html_color_to_v3i(html_color: String) -> Vector3i:
	var color := Color(html_color)
	return Vector3i(int(color.r), int(color.g), int(color.b))
	
	
func v3_to_pretty(v3: Vector3) -> String:
	return "(%s, %s, %s)" % [v3.x, v3.y, v3.z]
	
	
func v3i_to_pretty(v3i: Vector3i) -> String:
	return "(%s, %s, %s)" % [v3i.x, v3i.y, v3i.z]


func a3_to_v3(array: Array) -> Vector3:
	return Vector3(array[0], array[1], array[2])


func a2_to_v3(array: Array) -> Vector3:
	return Vector3(array[0], 0, array[1])


func a2_to_v2(array: Array) -> Vector2:
	return Vector2(array[0], array[1])


func a3_to_v3i(array: Array[float]) -> Vector3i:
	return Vector3i(floori(array[0]), floori(array[1]), floori(array[2]))


func v3_to_a3(v3: Vector3) -> Array[float]:
	return [snappedf(v3.x, 0.001), snappedf(v3.y, 0.001), snappedf(v3.z, 0.001)]


func v2_to_a2(v2: Vector2) -> Array[float]:
	return [snappedf(v2.x, 0.001), snappedf(v2.y, 0.001)]


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


func color_to_html_color(color : Color) -> String:
	return color.to_html()
	
	
func html_color_to_color(string : String) -> Color:
	return Color.html(string)


func safe_connect(disconnect_signal : Signal, callabe : Callable):
	if not disconnect_signal.is_connected(callabe):
		disconnect_signal.connect(callabe)


func safe_disconnect(connect_signal : Signal, callabe : Callable):
	if connect_signal.is_connected(callabe):
		connect_signal.disconnect(callabe)


func safe_queue_free(node: Variant):
	if is_instance_valid(node):
		node.queue_free()
		

func get_bitmask(x : int) -> int:
	return int(pow(2, x - 1))


func get_hit(from : Node3D, to_point : Vector3, raycast : PhysicsRayQueryParameters3D, 
		collision_mask : int, hit_back_faces: bool = true) -> Dictionary:
	var space_state := from.get_world_3d().direct_space_state
	raycast.from = from.global_position
	raycast.to = to_point
	raycast.collision_mask = collision_mask
	raycast.hit_back_faces = hit_back_faces
	return space_state.intersect_ray(raycast)


func get_mouse_hit(camera: Camera3D, from_center: bool, raycast: PhysicsRayQueryParameters3D, 
		collision_mask: int, hit_back_faces: bool = true) -> Dictionary:
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
	raycast.hit_back_faces = hit_back_faces
	return space_state.intersect_ray(raycast)
	
	
func action_shortcut(action_name):
	var input_event := InputEventAction.new()
	input_event.action = action_name
	var shortcut := Shortcut.new()
	shortcut.events = [input_event]
	return shortcut
	

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


func dump_json(path: String, data: Dictionary) -> void:
	var json_string := dumps_json(data)
	var file := FileAccess.open(path, FileAccess.WRITE)
	var open_error := FileAccess.get_open_error()
	if open_error:
		printerr("error writing json: %s" % error_string(open_error))
	file.store_line(json_string)


func make_dirs(path: String) -> void:
	var error := DirAccess.make_dir_recursive_absolute(path)
	if error:
		printerr("Error creating dirs: " + str(error))
		
		
func remove_dirs(path: String) -> void:
	var global_path := ProjectSettings.globalize_path(path)
	OS.move_to_trash(global_path)


func rename(from: String, to: String) -> Error:
	var error := DirAccess.rename_absolute(from, to)
	if error:
		printerr("Error renaming: " + str(error))
	return error


func create_unique_folder(path: String, sep_char := "-") -> int:
	var siblins := 1
	var unique_path := path

	while DirAccess.dir_exists_absolute(unique_path):
		siblins += 1
		var regex = RegEx.new()
		regex.compile(r"(.*?)%s(\d+)$" % sep_char)
		var matches := regex.search(unique_path)
		if matches:
			var groups := matches.get_strings()
			unique_path = "%s%s%s" % [groups[1], sep_char, int(groups[2]) + 1]
		else:
			unique_path = "%s%s%s" % [path, sep_char, siblins]

	make_dirs(unique_path)
	return siblins
	

func sort_strings_ended_with_number(array: Array[String]) -> Array[String]:
	var regex := RegEx.new()
	var pattern := r"(.*?)(\d+)$"
	regex.compile(pattern)
	array.sort_custom(func (a: String, b: String):
		var match_a := regex.search(a)
		var match_b := regex.search(b)
		if not match_a or not match_b:
			return a < b
			
		var groups_a := match_a.strings
		var groups_b := match_b.strings
		var text_a = groups_a[1]
		var text_b = groups_b[1]
		if text_a == text_b:
			var num_a = int(groups_a[2])
			var num_b = int(groups_b[2])
			return num_a < num_b
		else:
			return text_a < text_b
	)
	return array


func slugify(text: String) -> String:
	text = text.strip_edges().to_lower()
	var replacements = {
		" ": "-",
		"á": "a", "à": "a", "ä": "a", "â": "a", "ã": "a", "å": "a", "æ": "ae",
		"ç": "c", "č": "c", "ć": "c",
		"é": "e", "è": "e", "ë": "e", "ê": "e", "ě": "e",
		"í": "i", "ì": "i", "ï": "i", "î": "i",
		"ñ": "n", 
		"ó": "o", "ò": "o", "ö": "o", "ô": "o", "õ": "o", "ø": "o", "œ": "oe",
		"š": "s", "ß": "ss",
		"ú": "u", "ù": "u", "ü": "u", "û": "u",
		"ý": "y", "ÿ": "y",
		"ž": "z", "ź": "z", "ż": "z",
		"đ": "d", "ð": "d",
		"ł": "l",
		"þ": "th",
	}
	
	for original in replacements.keys():
		text = text.replace(original, replacements[original])

	var slug = ""
	for t in text:
		if t in "-abcdefghijklmnopqrstuvwxyz0123456789":
			slug += t

	return slug


func random_string(lenght := 8) -> String:
	var string := ""
	const CHARS : Array[String] = [
			"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", 
			"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", 
			"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", 
			"n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", 
			"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
	for i in range(0, lenght):
		string += CHARS.pick_random()
	return string


func png_to_texture(path: String) -> Texture2D:
	return ImageTexture.create_from_image(Image.load_from_file(path))
