extends Panel

@onready var texture_rect = $TextureRect
var slot_number: int

func _ready() -> void:
	Signals.update_inventory_slot.connect(func(s):
		if s != slot_number: return
		update()
	)

func update() -> void:
	if not is_node_ready():
		# Will this crash my computer...? find out soon
		update.call_deferred()
		return

	var item = Inventory.inventory[slot_number]
	
	if not item:
		texture_rect.visible = false
		return

	var data: ItemData = (item as ItemInstance).item_data
	texture_rect.texture = data.texture
