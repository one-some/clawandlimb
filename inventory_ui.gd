extends GridContainer

const slot_scene = preload("res://inventory_slot.tscn")
var slots  = []

func _ready() -> void:
	await get_tree().current_scene.ready
	
	for i in range(Inventory.SLOT_COUNT):
		var slot = slot_scene.instantiate()
		slots.append(slot)
		self.add_child(slot)
		
		slot.slot_number = i
		slot.update()
		slot.visible = i >= Inventory.HOTBAR_OFFSET
	
	set_hotbar_index(0)

func set_hotbar_index(index: int) -> void:
	slots[Inventory.active_hotbar_index].set_selected(false)
	Inventory.active_hotbar_index = index + Inventory.HOTBAR_OFFSET
	slots[Inventory.active_hotbar_index].set_selected(true)
	Signals.change_active_hotbar_slot.emit()

func process_hotbar_keys(event: InputEventKey) -> void:
	if not event.is_pressed(): return
	if event.is_echo(): return
	
	var idx = [
		KEY_1,
		KEY_2,
		KEY_3,
		KEY_4,
		KEY_5,
		KEY_6,
		KEY_7,
		KEY_8,
		KEY_9
	].find(event.physical_keycode)
	if idx == -1: return
	set_hotbar_index(idx)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey: return
	process_hotbar_keys(event)
