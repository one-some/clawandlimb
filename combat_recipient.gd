class_name CombatRecipient extends Object

signal died
signal took_damage(damage: float)

enum DamageOrigin {
	PLAYER,
	ENEMY,
	GOD
}

var name: String
var max_health: float
var health: float
var dead = false

func _init(name: String, max_health: float) -> void:
	self.name = name
	self.health = max_health
	self.max_health = max_health

func reset() -> void:
	health = max_health
	dead = false
	took_damage.emit(0.0)
	Signals.change_entity_health.emit(self, DamageOrigin.GOD, 0.0)

func take_damage(origin: DamageOrigin, damage: float) -> void:
	if dead: return
	
	var og_health = health
	health = clamp(health - damage, 0.0, max_health)
	
	took_damage.emit(damage)
	Signals.change_entity_health.emit(self, origin, og_health)

	if not health:
		dead = true
		died.emit()
