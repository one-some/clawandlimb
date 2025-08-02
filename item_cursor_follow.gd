extends Panel

func _physics_process(delta: float) -> void:
	if not Inventory.cursor_item:
		self.visible = false
		return
	
	self.visible = true
	$TextureRect.texture = Inventory.cursor_item.item_data.texture
	$Count.text = str(Inventory.cursor_item.count)
	
	self.position = get_global_mouse_position() - (self.size / 2)
	var lower_bound = self.position.y + self.size.y
	var screen_size = get_viewport_rect().size - Vector2(8, 8)
	
	if lower_bound > screen_size.y:
		self.position.y -= lower_bound - screen_size.y
