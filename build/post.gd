extends Constructable

func _ready() -> void:
	combat.name = "Post"
	super()
	print("Ready")

func set_start(pos: Vector3) -> void:
	self.global_position = pos

func set_end(pos: Vector3) -> void:
	self.global_position = pos
