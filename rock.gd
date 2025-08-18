extends Node3D

@export var item_drop: String = "stone"
@export var combat_name: String = "Rock"
var combat = CombatRecipient.new(combat_name, 20.0)

func _ready():
	combat.name = combat_name
	combat.took_damage.connect(_on_took_damage)
	combat.died.connect(_on_died)

func _on_took_damage(damage: float) -> void:
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
	
	Signals.drop_item.emit(
		ItemInstance.from_name(item_drop, randi_range(1, 4)),
		self.global_position + Vector3(0, 1, 0)
	)
	self.queue_free.call_deferred()
