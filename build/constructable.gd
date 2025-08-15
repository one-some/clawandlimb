class_name Constructable extends Node3D

var combat = CombatRecipient.new("Constructable", 10.0)
var start_pos = null
var end_pos = null
var one_and_done = false
var allow_freehand = false

func _ready() -> void:
	combat.died.connect(func(): self.queue_free())

func set_start(pos: Vector3) -> void:
	start_pos = pos

func set_end(pos: Vector3) -> void:
	end_pos = pos

func finalize() -> void:
	pass
