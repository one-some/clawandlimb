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

func _ready() -> void:
	assert(build_mode)
	combat.died.connect(func(): self.queue_free())

func set_start(pos: Vector3) -> void:
	start_pos = pos

func set_end(pos: Vector3) -> void:
	end_pos = pos

func finalize() -> void:
	pass
