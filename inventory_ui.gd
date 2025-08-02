extends GridContainer

const slot_scene = preload("res://inventory_slot.tscn")


func _ready() -> void:
	await get_tree().current_scene.ready
	
	for i in range(Inventory.SLOT_COUNT):
		var slot = slot_scene.instantiate()
		self.add_child(slot)
		
		slot.slot_number = i
		slot.update()
		slot.visible = i >= Inventory.HOTBAR_OFFSET

func _input(event: InputEvent) -> void:
	if not Input.is_action_just_pressed("inventory"): return
	
	if State.active_ui and State.active_ui != State.ActiveUI.INVENTORY:
		return
	
	State.active_ui = State.ActiveUI.INVENTORY if not State.active_ui else State.ActiveUI.NONE
	var open = State.active_ui == State.ActiveUI.INVENTORY
	
	var i = 0
	for c in self.get_children():
		c.visible = open or i >= Inventory.HOTBAR_OFFSET
		i += 1
	
	Signals.ui_blur.emit(open)
