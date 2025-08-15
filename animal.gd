# Good luck BABE!
class_name Animal extends CharacterBody3D

enum AnimalState {
	WANDERING,
	FLEEING,
	THINKING
}

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var wander_timer: Timer = $WanderTimer
@onready var hurt_timer: Timer = $HurtTimer
var combat = CombatRecipient.new("Pig", 14.0)
var state = AnimalState.WANDERING

func _ready() -> void:
	combat.died.connect(_on_died)
	combat.took_damage.connect(_on_took_damage)
	
	wander_timer.timeout.connect(_on_done_thinking)
	hurt_timer.timeout.connect(func(): state = AnimalState.WANDERING)
	think_where_to_go()

func _on_took_damage(damage: float) -> void:
	state = AnimalState.FLEEING
	think_where_to_go()
	hurt_timer.start()

func _on_died() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SPRING)
	tween.tween_property($BABE, "scale:x", 0.0, 1.0)
	tween.play()
	await tween.finished
	
	Signals.drop_item.emit(
		ItemInstance.from_name("ham", randi_range(0, 2)),
		self.global_position + Vector3(0, 1, 0)
	)
	
	self.queue_free()

func go_somewhere() -> void:
	state = AnimalState.THINKING

func think_where_to_go() -> void:
	if state == AnimalState.THINKING: return
	
	if state != AnimalState.FLEEING:
		state = AnimalState.THINKING
	
	var target = self.global_position + Vector3(
		randf_range(0.3, 1.0) * (1 if randf() < 0.5 else -1),
		0.0,
		randf_range(0.3, 1.0) * (1 if randf() < 0.5 else -1),
	) * 10.0
	
	agent.target_position = NavigationServer3D.map_get_closest_point(
		agent.get_navigation_map(),
		target
	)
	
	if state != AnimalState.FLEEING:
		wander_timer.start(randf_range(3.0, 6.0))

func _on_done_thinking() -> void:
	if state != AnimalState.THINKING: return
	state = AnimalState.WANDERING

func _physics_process(delta: float) -> void:
	if combat.dead:
		return
	
	if not self.is_on_floor():
		self.velocity.y -= State.gravity * delta
	
	self.velocity.x = 0.0
	self.velocity.z = 0.0
	
	if state == AnimalState.THINKING:
		pass
	elif agent.is_navigation_finished():
		think_where_to_go()
	else:
		var path_pos = agent.get_next_path_position()
		if path_pos.is_equal_approx(self.global_position):
			think_where_to_go()
			return
		
		var speed = 6.0 if state == AnimalState.FLEEING else 3.0
		var vel = self.global_position.direction_to(path_pos) * speed
		#print(path_pos, " - ", self.global_position)
		self.velocity.x = vel.x
		self.velocity.z = vel.z
	
	self.move_and_slide()
