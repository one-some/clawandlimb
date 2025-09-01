extends Panel

const Main = preload("res://main.tscn")

@onready var world_name: Label = %WorldName
@onready var world_size: Label = %WorldSize
@onready var last_played: Label = %LastPlayed

var save: WorldSave

func setup(save: WorldSave) -> void:
	self.save = save
	var meta_data = save.get_meta_data()
	
	world_name.text = meta_data["name"]
	world_size.text = save.get_size_string()
	last_played.text = (
		Time.get_datetime_string_from_unix_time(meta_data["last_played"], true)
	)


func _on_play_pressed() -> void:
	State.active_save = save
	get_tree().change_scene_to_packed(Main)

func _on_delete_pressed() -> void:
	OS.alert("No way. Nuh uh. Won't do it.", "Claire Says:")
