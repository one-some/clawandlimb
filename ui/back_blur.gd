extends Panel

func _ready() -> void:
	Signals.ui_blur.connect(_on_blur)

func _on_blur(enabled: bool) -> void:
	var panel_box: StyleBoxFlat = self.get_theme_stylebox("panel")
	
	if enabled:
		panel_box.bg_color.a = 0.0
		self.visible = true
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN if enabled else Tween.EASE_OUT)
	tween.tween_property(panel_box, "bg_color:a", 0.6 if enabled else 0.0, 0.1)
	tween.play()
	
	await tween.finished
	self.visible = enabled
