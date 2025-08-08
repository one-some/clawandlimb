extends Node

const SLOT_COUNT = 9 * 4
const HOTBAR_OFFSET = 9 * 3
var inventory: Array[ItemInstance] = []
var cursor_item: ItemInstance = null
var active_hotbar_index = 0

func set_slot(slot: int, item_instance: ItemInstance) -> void:
	inventory[slot] = item_instance
	Signals.update_inventory_slot.emit(slot)

func to_json() -> Variant:
	return inventory.map(func(x): return x.to_json() if x else null)

func from_json(data):
	for i in range(data.size()):
		var item = data[i]
		if not item: continue
		set_slot(i, ItemInstance.from_json(item))
	Signals.change_active_hotbar_slot.emit()

func _ready() -> void:
	inventory.resize(9 * 4)
	inventory.fill(null)
	
	Save.register_handler("inventory", to_json, from_json)
	
	Signals.try_pickup_item.connect(add)

func prioritized_indices() -> Array:
	# Is it hack....? Maybe..
	return range(HOTBAR_OFFSET, inventory.size()) + range(HOTBAR_OFFSET)

func add(item_instance: ItemInstance) -> bool:
	# First try to fill incomplete stacks of the same type
	for i in prioritized_indices():
		var item = inventory[i]
		if not item: continue
		if not item.item_data.equals(item_instance.item_data): continue
		var space_remaining = item.item_data.max_stack - item.count
		if space_remaining <= 0: continue
		
		if item_instance.count <= space_remaining:
			item.count += item_instance.count
			Signals.update_inventory_slot.emit(i)
			return true
		
		# We have more to do.
		item_instance.count -= space_remaining
		item.count = item.item_data.max_stack
		Signals.update_inventory_slot.emit(i)
	
	# Now add into empty slots
	for i in prioritized_indices():
		var item = inventory[i]
		if item: continue
		
		# TODO: If we get 128 dirt and dirt only stacks to 64, split into two stacks!!
		set_slot(i, item_instance)
		return true
	
	print("BAD NEWS")
	return false
