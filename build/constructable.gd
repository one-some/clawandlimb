class_name Constructable extends Node3D

var start_pos = null
var end_pos = null
var is_finalized = false

# TODO: Static somehow but it needs to be modifiable when inherited,,,,,,,,,,,,!!!!
var allow_freehand = false
@export var load_priority = 0

# TODO: Export
var combat = CombatRecipient.new("Constructable", 10.0)
var real_resource_path = self.scene_file_path
@export var build_mode: State.BuildMode = State.BuildMode.NONE

func is_one_and_done() -> bool:
	return build_mode in [
		State.BuildMode.PLACE_MODEL,
		State.BuildMode.PLACE_DOOR,
	]

func to_json() -> Dictionary:
	assert(is_finalized)
	assert(real_resource_path)
	
	var out = {
		"scene_path": real_resource_path,
		"position": Util.vector3_to_array(self.global_position),
	}
	
	if start_pos != null: out["start_pos"] = Util.vector3_to_array(start_pos)
	if end_pos != null: out["end_pos"] = Util.vector3_to_array(end_pos)
	
	return out

static func from_json(data: Dictionary) -> Dictionary:
	#print("LOADING FROM JSON ", data)
	var thing = load(data["scene_path"])
	
	if thing is ModifiedConstructable:
		thing = thing.create()
	elif thing is PackedScene:
		thing = thing.instantiate()
	
	assert(thing is Constructable)
	thing = (thing as Constructable)
	
	# This whole thing has to be a closure because we need to sort them by
	# load_order before we instantiate them
	return {
		"constructable": thing,
		"instantiate": func(parent: BuildManager) -> void:
			parent.add_child(thing)
			thing.global_position = Util.vector3_from_array(data["position"])
			
			if "start_pos" in data: thing.set_start(Util.vector3_from_array(data["start_pos"]))
			if "end_pos" in data: thing.set_end(Util.vector3_from_array(data["end_pos"]))
			thing._finalize()
	}
	

func _ready() -> void:
	assert(build_mode)
	combat.died.connect(func(): self.queue_free())

func register_path(new_path: String) -> void:
	assert("::" not in new_path)
	assert(new_path)
	print("CHANGING RES PATH FROM ", self.real_resource_path, " TO ", new_path)
	self.real_resource_path = new_path

func process_modifications(modified: ModifiedConstructable) -> void:
	pass

func set_start(pos: Vector3) -> void:
	start_pos = pos

func set_end(pos: Vector3) -> void:
	end_pos = pos

func _finalize() -> void:
	is_finalized = true
	finalize()

func finalize() -> void:
	pass
