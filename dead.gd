extends Panel

@onready var respawn_button: Button = $VBoxContainer/Respawn

func _ready() -> void:
	Signals.player_died.connect(die)

func die() -> void:
	State.set_active_ui(State.ActiveUI.DEAD)

	self.modulate.a = 0.0
	self.visible = true
	
	respawn_button.disabled = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.8, 1.5)
	#tween.tween_interval(0.)
	await tween.finished
	respawn_button.disabled = false


func _on_button_pressed() -> void:
	State.set_active_ui(State.ActiveUI.NONE)
	Signals.player_respawn_requested.emit()
	self.visible = false
