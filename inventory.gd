extends Node

const SLOT_COUNT = 9 * 4
const HOTBAR_OFFSET = 9 * 3
var inventory: Array[ItemInstance] = []
var cursor_item: ItemInstance = null

func _ready() -> void:
	inventory.resize(9 * 4)
	inventory.fill(null)
	
	var inst = ItemInstance.new(
		ItemRegistry.get_item_data("dirt"),
		28,
	)
	add(inst)

func prioritized_indices() -> Array:
	# Is it hack....? Maybe..
	return range(HOTBAR_OFFSET, inventory.size()) + range(HOTBAR_OFFSET)

func add(item_instance: ItemInstance) -> void:
	print(prioritized_indices())
	
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
			return
		
		# We have more to do.
		item_instance.count -= space_remaining
		item.count = item.item_data.max_stack
		Signals.update_inventory_slot.emit(i)
	
	# Now add into empty slots
	for i in prioritized_indices():
		var item = inventory[i]
		if item: continue
		print(i)
		
		# TODO: If we get 128 dirt and dirt only stacks to 64, split into two stacks!!
		inventory[i] = item_instance
		Signals.update_inventory_slot.emit(i)
		return
	
	print("BAD NEWS")
