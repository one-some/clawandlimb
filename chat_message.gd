extends Control

func _ready() -> void:
	var tween = create_tween()
	tween.tween_interval(5.0)
	tween.tween_property(self, "modulate:a", 0, 5.0)
	tween.tween_callback(self.queue_free)
	tween.play()

func set_message(text: String) -> void:
	self.text = text
