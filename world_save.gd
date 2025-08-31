class_name WorldSave extends RefCounted

var dir_path: String

func _init(p_dir_path: String) -> void:
	dir_path = p_dir_path

func _read_json(path: String) -> Variant:
	var text = FileAccess.get_file_as_string(path)
	var out = JSON.parse_string(text)
	assert(out)
	return out

func get_meta_data() -> Dictionary:
	return _read_json(dir_path.path_join("meta.json"))

func _sum_up_dir_size(path: String, sum: int = 0) -> int:
	var dir = DirAccess.open(path)
	assert(dir)
	
	for file_name in dir.get_files():
		var file = FileAccess.open(path.path_join(file_name), FileAccess.READ)
		# TODO: Godot 4.5: FileAccess.get_size() https://github.com/godotengine/godot/pull/83538
		sum += file.get_length()
	
	for other_dir in dir.get_directories():
		sum += _sum_up_dir_size(path.path_join(other_dir))
	
	return sum

func get_size_bytes() -> int:
	return _sum_up_dir_size(dir_path)

func get_size_string() -> String:
	var n = get_size_bytes()
	var labels = ["Bytes", "KiB", "MiB", "GiB (Lord Forbid)", "TiB (Lord Forbid Even More)"]
	
	while labels.size() > 1:
		if n / 1024.0 < 1.0:
			break
		
		labels.remove_at(0)
		n /= 1024.0
	
	
	var n_out = snapped(n, 0.01) if n != round(n) else n
	return "%s %s" % [n_out, labels[0]]
