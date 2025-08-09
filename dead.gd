extends Panel

func _ready() -> void:
	Signals.player_died.connect(die)

func die() -> void:
	State.active_ui = State.ActiveUI.DEAD

	self.modulate.a = 0.0
	self.visible = true
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.8, 1.0)


func _on_button_pressed() -> void:
	State.active_ui = State.ActiveUI.NONE
	Signals.player_respawn_requested.emit()
	self.visible = false
