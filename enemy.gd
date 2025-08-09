extends CharacterBody3D

@onready var target = get_tree().get_first_node_in_group("Player")
@onready var attack_timer = $"AttackCooldownTimer"
var combat = CombatRecipient.new("Zombie", 10.0)
var can_attack = true
const CLOSE_ENOUGH = 0.8

func _ready() -> void:
	attack_timer.timeout.connect(func(): can_attack = true)
	combat.died.connect(func(): self.queue_free())

func _physics_process(delta: float) -> void:
	if not self.is_on_floor():
		self.velocity.y -= 14.0 * delta
	self.move_and_slide()
	
	try_attack()

func attack() -> void:
	if not can_attack: return
	can_attack = false
	attack_timer.start()
	
	target.alter_health(-randi_range(10, 15))

func try_attack() -> void:
	if not can_attack: return
	if self.global_position.distance_to(target.global_position) > CLOSE_ENOUGH: return
	attack()
