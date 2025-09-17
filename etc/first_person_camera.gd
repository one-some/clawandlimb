extends Camera3D

@onready var player: CharacterBody3D = self.get_parent()

func _ready() -> void:
	Signals.ui_changed.connect(_on_ui_changed)

func _input(event: InputEvent) -> void:
	if not self.current: return
	if State.active_ui: return
	
	if event is InputEventMouseMotion:
		player.rotation.y -= event.relative.x / 300.0
		self.rotation.x = clampf(
			self.rotation.x - (event.relative.y / 300.0),
			(-PI / 2.0) + 0.001,
			PI / 2.0
		)

func set_active(active: bool) -> void:
	self.current = active
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE

func _on_ui_changed(active_ui: State.ActiveUI) -> void:
	if active_ui:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif self.current:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
