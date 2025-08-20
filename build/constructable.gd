class_name Constructable extends Node3D

var start_pos = null
var end_pos = null
var allow_freehand = false

# TODO: Export
var combat = CombatRecipient.new("Constructable", 10.0)
@export var build_mode: State.BuildMode = State.BuildMode.NONE

func is_one_and_done() -> bool:
	return build_mode in [
		State.BuildMode.PLACE_MODEL,
		State.BuildMode.PLACE_DOOR,
	]

func to_json() -> Dictionary:
	assert(self.scene_file_path)
	
	return {
		"scene_path": self.scene_file_path,
		"position": Save.vec_to_array(self.global_position),
		"start_pos": Save.vec_to_array(start_pos),
		"end_pos": Save.vec_to_array(end_pos),
	}

func from_json(data: Dictionary) -> void:
	print("LOADING FROM JSON ", data)
	if data["position"]:
		self.global_position = Save.array_to_vec(data["position"])
	
	# UGHHH
	
	var start = Save.array_to_vec(data["start_pos"])
	var end = Save.array_to_vec(data["end_pos"])
	
	if start != null: self.set_start(start)
	if end != null: self.set_end(end)
	
	self.finalize()

func _ready() -> void:
	assert(build_mode)
	combat.died.connect(func(): self.queue_free())

func set_start(pos: Vector3) -> void:
	start_pos = pos

func set_end(pos: Vector3) -> void:
	end_pos = pos

func finalize() -> void:
	pass
