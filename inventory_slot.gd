extends Panel

@onready var texture_rect = $TextureRect
@onready var count_label = $Count
var slot_number: int
var hovering = false

func _ready() -> void:
	Signals.update_inventory_slot.connect(func(s):
		if s != slot_number: return
		update()
	)

func set_item(item_instance: ItemInstance) -> void:
	Inventory.inventory[slot_number] = item_instance
	update()

func get_item() -> ItemInstance:
	return Inventory.inventory[slot_number]

func update() -> void:
	var item = get_item()
	
	if not item:
		texture_rect.visible = false
		count_label.visible = false
		return
	
	texture_rect.visible = true
	count_label.visible = false
	
	var data: ItemData = item.item_data
	texture_rect.texture = data.texture
	count_label.visible = item.count > 1
	count_label.text = str(item.count)

func _on_mouse_entered() -> void:
	hovering = true
	print("OKAY")
	
	var item = get_item()
	if item:
		Signals.tooltip_set_item.emit(item)
	else:
		Signals.tooltip_clear.emit()

func _on_mouse_exited() -> void:
	hovering = false
	
	Signals.tooltip_clear.emit()

func _on_click() -> void:
	var item = get_item()
	
	if not (item or Inventory.cursor_item):
		return
	
	# I'm sure this could be cleaner...
	if item and not Inventory.cursor_item:
		Inventory.cursor_item = item
		set_item(null)
	elif Inventory.cursor_item and not item:
		set_item(Inventory.cursor_item)
		Inventory.cursor_item = null
	else:
		# BOTH. Now we swap.
		set_item(Inventory.cursor_item)
		Inventory.cursor_item = item
	

func _input(event: InputEvent) -> void:
	if not hovering: return
	if not Input.is_action_just_pressed("click"): return
	_on_click()
