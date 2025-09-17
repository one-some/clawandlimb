extends Panel

func _ready() -> void:
	self.visible = true
	Signals.update_loading_status.connect(_on_update_loading_status)
	await get_tree().process_frame
	self.visible = false

func _on_update_loading_status(what: String) -> void:
	$Label.text = what
