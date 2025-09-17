extends Control

@onready var inventory_grid = $Cont/Inv/Inventory
@onready var crafting_ui = $Cont/Crafting
@onready var player_ui = $Cont/Inv/PlayerPreview

func _ready() -> void:
	self.visible = true
	set_inventory_open(false)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey: return
	if not event.pressed: return
	
	if State.active_ui and State.active_ui != State.ActiveUI.INVENTORY:
		return
	
	if event.is_action("inventory"):
		State.set_active_ui(State.ActiveUI.INVENTORY if not State.active_ui else State.ActiveUI.NONE)
	elif event.is_action("esc"):
		State.set_active_ui(State.ActiveUI.NONE)
	else:
		return
	
	set_inventory_open(State.active_ui == State.ActiveUI.INVENTORY)

func set_inventory_open(open: bool) -> void:
	crafting_ui.visible = open
	player_ui.visible = open
	
	var i = 0
	for c in inventory_grid.get_children():
		c.visible = open or i >= Inventory.HOTBAR_OFFSET
		i += 1
	
	Signals.ui_blur.emit(open)
