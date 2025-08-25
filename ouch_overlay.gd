extends TextureRect

func _ready() -> void:
	self.visible = true
	self.modulate = Color.TRANSPARENT
	Signals.change_player_health.connect(_on_change_player_health)

func _process(delta: float) -> void:
	if self.modulate.a <= 0.01:
		return
	self.modulate.a -= 0.01

func _on_change_player_health(combat: CombatRecipient, delta: float) -> void:
	print("FREAKING YIKES")
	self.modulate.a = clamp(-delta * 2.0 / combat.max_health, 0.0, 1.0)
