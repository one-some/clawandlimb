class_name PlayerSave extends RefCounted

var world_save: WorldSave
var player_name: String
var player_meta: Dictionary
var player_body: Player

func _init(world_save: WorldSave, player_name: String) -> void:
	assert(player_name.is_valid_filename())
	
	self.world_save = world_save
	self.player_name = player_name
	
	var path = get_dir_path()
	if not DirAccess.dir_exists_absolute(path):
		player_meta = {
			"position": null,
		}
	else:
		player_meta = Util.read_json(path.path_join("player.json"))
	
	assert("position" in player_meta)

func register_player_body(body: Player) -> void:
	player_body = body

func get_position() -> Variant:
	var array = player_meta["position"]
	if array == null: return null
	return Vector3(array[0], array[1], array[2])

func get_dir_path() -> String:
	return world_save.dir_path.path_join("players").path_join(player_name)

func write() -> void:
	assert(player_name.is_valid_filename())
	assert(player_body)
	
	var path = get_dir_path()
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)
	
	var pos = player_body.global_position
	player_meta["position"] = [pos.x, pos.y, pos.z]
	
	Util.write_json(path.path_join("player.json"), player_meta)
