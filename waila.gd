extends Panel

@onready var progress_bar = $ProgressBar
@onready var label = $Label

const FADE_TIMER_MAX = 4.0
var fade_timer = 0.0

func _ready() -> void:
	self.visible = true
	Signals.change_entity_health.connect(_on_change_entity_health)

func _physics_process(delta: float) -> void:
	fade_timer = max(0.0, fade_timer - delta)
	self.modulate.a = min(2.0, fade_timer) / 2.0

func _on_change_entity_health(
	combat: CombatRecipient,
	origin: CombatRecipient.DamageOrigin,
	og_health: float
) -> void:
	if origin != CombatRecipient.DamageOrigin.PLAYER: return

	label.text = combat.name
	fade_timer = FADE_TIMER_MAX
	
	progress_bar.max_value = combat.max_health
	progress_bar.value = og_health
	
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", combat.health, 0.1)
	tween.play()
