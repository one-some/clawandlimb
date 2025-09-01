extends VBoxContainer

const WorldEntry = preload("res://world_ui_entry.tscn")

func _ready() -> void:
	for save in Save.get_saves():
		var panel = WorldEntry.instantiate()
		self.add_child(panel)
		panel.setup(save)
