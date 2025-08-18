extends Node

const SAVE_PATH = "user://save.json"
var handlers = {}

func _ready() -> void:
	await get_viewport().ready
	await get_tree().process_frame
	load_save()

func vec_to_array(vec: Vector3) -> Variant:
	if not vec: return null
	return [vec.x, vec.y, vec.z]

func array_to_vec(array: Array) -> Vector3:
	assert(array.size() == 3)
	return Vector3(array[0], array[1], array[2])

func register_handler(id: String, to_json: Callable, from_json: Callable) -> void:
	assert(id not in handlers)
	handlers[id] = {"to_json": to_json, "from_json": from_json}

func save() -> void:
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	for handler in handlers:
		#if node.scene_file_path.is_empty():
			#print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			#continue
		var data = {
			"handler": handler,
			"data": handlers[handler]["to_json"].call() 
		}
		var json_string = JSON.stringify(data)
		save_file.store_line(json_string)

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No file")
		return

	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var line = save_file.get_line()

		var json = JSON.new()
		var parse_result = json.parse(line)
		if parse_result != OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", line, " at line ", json.get_error_line())
			continue

		var data = json.data
		handlers[data["handler"]]["from_json"].call(data["data"])
