extends StaticBody3D

@export var health = 7.0
@onready var particles: GPUParticles3D = $GPUParticles3D

func drop_leaves(n: int) -> void:
	for _i in range(n):
		particles.emit_particle(Transform3D.IDENTITY, Vector3.ZERO, Color.WHITE, Color.WHITE, 0)

func take_damage(damage: float) -> void:
	if not health: return
	
	# the axeman comes swift ...
	health = max(0.0, health - damage)
	print(health)
	
	# leaves falling from autumn trees ...
	drop_leaves(randi_range(1, 7))
	Signals.camera_shake.emit(0.05, self.global_position)
	
	# shuddering willows.
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
	
	if not health:
		die()

func die():
	if health: return
	
	$CollisionShape3D.disabled = true
	
	particles.lifetime = 6.0
	particles.explosiveness = 1.0
	(particles.process_material as ParticleProcessMaterial).initial_velocity_min = 20.0
	(particles.process_material as ParticleProcessMaterial).initial_velocity_min = 20.0
	(particles.process_material as ParticleProcessMaterial).spread = 180.0
	
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(
		self,
		"rotation_degrees:" + ["x", "z"].pick_random(),
		66.6 * [-1, 1].pick_random(),
		2.0
	)
	#tween.tween_callback(drop_leaves.bind(30))
	tween.tween_callback(Signals.camera_shake.emit.bind(1.0, self.global_position))
	tween.tween_interval(1.5)
	tween.tween_callback(func():
		particles.restart()
		particles.reparent(self.get_parent())
		particles.emitting = true
		self.queue_free.call_deferred()
	)
	#tween.tween_callback(func(): self.visible = false)
	
	
	tween.play()
