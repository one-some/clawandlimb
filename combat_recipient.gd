class_name CombatRecipient extends Object

signal died
signal took_damage(damage: float)

var name: String
var max_health: float
var health: float
var dead = false

func _init(name: String, max_health: float) -> void:
	self.name = name
	self.health = max_health
	self.max_health = max_health

func take_damage(damage: float) -> void:
	if dead: return
	
	took_damage.emit(damage)
	
	var og_health = health
	health = clamp(health - damage, 0.0, max_health)
	Signals.change_entity_health.emit(self, og_health)

	if not health:
		dead = true
		died.emit()
