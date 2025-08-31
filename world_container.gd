extends VBoxContainer

const WorldEntry = preload("res://world_ui_entry.tscn")

func _ready() -> void:
	for save in Save.get_saves():
		var meta_data = save.get_meta_data()
		
		var panel = WorldEntry.instantiate()
		(panel.get_node("%WorldName") as Label).text = meta_data["name"]
		(panel.get_node("%WorldSize") as Label).text = save.get_size_string()
		(panel.get_node("%LastPlayed") as Label).text = (
			Time.get_datetime_string_from_unix_time(meta_data["last_played"], true)
		)
		
		self.add_child(panel)
