extends Panel

@onready var progress_bar = $ProgressBar
@onready var label = $Label

const FADE_TIMER_MAX = 4.0
var fade_timer = 0.0

func _ready() -> void:
	Signals.change_entity_health.connect(_on_change_entity_health)

func _physics_process(delta: float) -> void:
	fade_timer = max(0.0, fade_timer - delta)
	self.modulate.a = min(2.0, fade_timer) / 2.0
	print(fade_timer, " Real: ", self.modulate.a)

func _on_change_entity_health(
	combat: CombatRecipient,
	og_health: float
) -> void:
	label.text = combat.name
	fade_timer = FADE_TIMER_MAX
	
	progress_bar.max_value = combat.max_health
	progress_bar.value = og_health
	
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", combat.health, 0.1)
	tween.play()
