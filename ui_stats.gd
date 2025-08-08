extends Control

func _ready() -> void:
	Signals.change_player_health.connect(_on_change_player_health)

func _on_change_player_health(health: float, max_health: float) -> void:
	$HP.max_value = max_health
	$HP.value = health
