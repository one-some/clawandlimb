extends Camera3D

@onready var player: CharacterBody3D = self.get_parent()

func _input(event: InputEvent) -> void:
	if not self.current: return
	
	if event is InputEventMouseMotion:
		player.rotation.y -= event.relative.x / 300.0
		self.rotation.x = clampf(
			self.rotation.x - (event.relative.y / 300.0),
			-PI / 2.0,
			PI / 2.0
		)

func set_active(active: bool) -> void:
	self.current = active
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE
