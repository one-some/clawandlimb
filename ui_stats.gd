extends Control

@onready var hp_bar = $HP
@onready var equipped_label = $EquippedLabel

func _ready() -> void:
	Signals.change_player_health.connect(_on_change_player_health)
	Signals.change_active_hotbar_slot.connect(_on_slot_change)

func _on_change_player_health(combat: CombatRecipient, delta: float) -> void:
	hp_bar.max_value = combat.max_health
	hp_bar.value = combat.health

func _on_slot_change() -> void:
	var item = Inventory.active_item()
	equipped_label.visible = not not item
	if not item: return
	equipped_label.text = item.item_data.item_name
