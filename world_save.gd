class_name WorldSave extends RefCounted

var dir_path: String
var meta: Dictionary

func _init(p_dir_path: String) -> void:
	dir_path = p_dir_path
	
	meta = get_meta_data()
	assert(meta["name"] is String)
	assert(meta["worldgen"] is String)
	assert(typeof(meta["last_played"]) in [TYPE_INT, TYPE_FLOAT])
	assert(meta["seed"] is String)

func get_seed_int() -> int:
	return meta["seed"].hash() + 09142008

func get_worldgen_algorithm() -> VoxelMesh.Worldgen:
	match meta["worldgen"]:
		"flat_basic":
			return VoxelMesh.WORLDGEN_FLAT
		"kitty":
			return VoxelMesh.WORLDGEN_KITTY

	assert(false)
	return VoxelMesh.WORLDGEN_FLAT

func get_meta_data() -> Dictionary:
	return Util.read_json(dir_path.path_join("meta.json"))

func get_size_bytes() -> int:
	return Util.get_directory_space_usage(dir_path)

func get_size_string() -> String:
	return Util.format_bytes_1024(get_size_bytes())
