extends WorldEnvironment

func _input(event: InputEvent) -> void:
	if event is not InputEventKey: return
	if not event.pressed: return
	if not event.is_action("debug_toggle_fog"): return
	self.environment.fog_enabled = not self.environment.fog_enabled
