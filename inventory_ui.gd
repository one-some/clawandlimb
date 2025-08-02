extends GridContainer

const slot_scene = preload("res://inventory_slot.tscn")


func _ready() -> void:
	for i in range(Inventory.SLOT_COUNT):
		var slot = slot_scene.instantiate()
		#await slot.ready
		
		slot.slot_number = i
		slot.update()
		slot.visible = i >= Inventory.HOTBAR_OFFSET
		if i >= Inventory.HOTBAR_OFFSET: slot.get_children()[0].queue_free()
		self.add_child(slot)

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
