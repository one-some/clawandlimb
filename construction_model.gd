extends StaticBody3D

var combat = CombatRecipient.new("Doodad", 10.0)
var start_pos = null
var end_pos = null

func _ready() -> void:
	combat.died.connect(func(): self.queue_free())

func set_start(pos: Vector3) -> void:
	self.global_position = pos

func set_end(pos: Vector3) -> void:
	self.global_position = pos

func finalize() -> void:
	pass
