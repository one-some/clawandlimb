class_name WorldSave extends RefCounted

static var STOCK_WORLDS_PATH = "res://data/importworlds"
static var USER_WORLDS_PATH = "user://worlds/"

const WorldgenTypes = {
	"flat_basic": VoxelMesh.WORLDGEN_FLAT,
	"kitty": VoxelMesh.WORLDGEN_KITTY,
}

var dir_path: String
var meta: Dictionary
var players: Dictionary[String, PlayerSave]

static func create(
	name: String,
	worldgen: VoxelMesh.Worldgen,
	seed: String
) -> WorldSave:
	assert(name.is_valid_filename())
	
	var path = USER_WORLDS_PATH.path_join(name)
	
	assert(not DirAccess.dir_exists_absolute(path))
	DirAccess.make_dir_absolute(path)
	assert(DirAccess.dir_exists_absolute(path))
	
	Util.write_json(
		path.path_join("meta.json"),
		{
			"name": name,
			"worldgen": WorldgenTypes.find_key(worldgen),
			"seed": seed,
			"last_played": Time.get_unix_time_from_system(),
			"save_version": 0.1,
		}
	)
	return WorldSave.new(path)

func _init(p_dir_path: String) -> void:
	dir_path = p_dir_path
	
	meta = get_meta_data()
	assert(meta["name"] is String)
	assert(meta["worldgen"] is String)
	assert(typeof(meta["last_played"]) in [TYPE_INT, TYPE_FLOAT])
	assert(meta["seed"] is String)
	assert(typeof(meta["save_version"]) in [TYPE_INT, TYPE_FLOAT])
	
	for player in DirAccess.get_directories_at(dir_path.path_join("players")):
		players[player] = PlayerSave.new(self, player)
		print("Loaded player '%s' !" % player)

func write() -> void:
	Util.write_json(dir_path.path_join("meta.json"), meta)
	
	for player_save in players.values():
		player_save.write()

func get_seed_int() -> int:
	return meta["seed"].hash() + 09142008

func get_worldgen_algorithm() -> VoxelMesh.Worldgen:
	return WorldgenTypes[meta["worldgen"]]

func get_meta_data() -> Dictionary:
	var out = Util.read_json(dir_path.path_join("meta.json"))
	
	if "save_version" not in out: out["save_version"] = 0.0
	
	return out

func get_size_bytes() -> int:
	return Util.get_directory_space_usage(dir_path)

func get_size_string() -> String:
	return Util.format_bytes_1024(get_size_bytes())
