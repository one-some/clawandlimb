extends StaticBody3D

var combat = CombatRecipient.new("Tree", 20.0)
@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready():
	combat.took_damage.connect(_on_took_damage)
	combat.died.connect(_on_died)

func drop_leaves(n: int) -> void:
	for _i in range(n):
		particles.emit_particle(Transform3D.IDENTITY, Vector3.ZERO, Color.WHITE, Color.WHITE, 0)

func _on_took_damage(damage: float) -> void:
	drop_leaves(randi_range(1, 7))
	
	Signals.camera_shake.emit(0.05, self.global_position)
	
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	var key = "rotation_degrees:" + ["x", "z"].pick_random()
	tween.tween_property(
		self,
		key,
		randf_range(-1.0, -3.0),
		0.1
	)
	tween.tween_property(self, key, 0.0, 0.1)
	tween.play()

func _impact() -> void:
	Signals.camera_shake.emit.bind(1.0, self.global_position)

func _on_died():
	$CollisionShape3D.disabled = true
	
	particles.lifetime = 6.0
	particles.explosiveness = 1.0
	(particles.process_material as ParticleProcessMaterial).initial_velocity_min = 20.0
	(particles.process_material as ParticleProcessMaterial).initial_velocity_min = 20.0
	(particles.process_material as ParticleProcessMaterial).spread = 180.0
	
	anim_player.play("Fall")
	await anim_player.animation_finished
	# No not that kind of tree
	await get_tree().create_timer(1.0).timeout
	
	Signals.drop_item.emit(
		ItemInstance.from_name("log", randi_range(3, 6)),
		self.global_position + Vector3(0, 3, 0)
	)
	particles.restart()
	particles.reparent(self.get_parent())
	particles.emitting = true
	self.queue_free.call_deferred()
