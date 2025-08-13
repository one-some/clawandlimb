extends Constructable

func _ready() -> void:
	combat.name = "Doodad"
	one_and_done = true

func set_start(pos: Vector3) -> void:
	self.global_position = pos

func set_end(pos: Vector3) -> void:
	self.global_position = pos
