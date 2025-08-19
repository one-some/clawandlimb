extends Constructable

func _ready() -> void:
	combat.name = self.name
	super()

func set_start(pos: Vector3) -> void:
	self.global_position = pos

func set_end(pos: Vector3) -> void:
	self.global_position = pos
