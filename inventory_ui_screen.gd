extends Control

@onready var inventory_grid = $Cont/Inv/Inventory
@onready var crafting_ui = $Cont/Crafting

func _input(event: InputEvent) -> void:
	if not event is InputEventKey: return
	
	if State.active_ui and State.active_ui != State.ActiveUI.INVENTORY:
		return
	
	if Input.is_action_just_pressed("inventory"):
		State.active_ui = State.ActiveUI.INVENTORY if not State.active_ui else State.ActiveUI.NONE
	elif Input.is_action_just_pressed("esc"):
		State.active_ui = State.ActiveUI.NONE
	else:
		return
	
	var open = State.active_ui == State.ActiveUI.INVENTORY
	crafting_ui.visible = open
	
	var i = 0
	for c in inventory_grid.get_children():
		c.visible = open or i >= Inventory.HOTBAR_OFFSET
		i += 1
	
	Signals.ui_blur.emit(open)
