extends Control

@onready var map = $Map

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.pressed: return
		
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				map.zoom(1.5)
			MOUSE_BUTTON_WHEEL_DOWN:
				map.zoom(0.75)
			_:
				return
		print("Bruhhhh")
		self.accept_event()
