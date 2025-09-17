extends Node

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	DirAccess.make_dir_absolute(WorldSave.USER_WORLDS_PATH)

func _notification(what):
	if what != NOTIFICATION_WM_CLOSE_REQUEST: return

	print("Saving...")
	State.active_save.write()
	print("Done saving!")
	get_tree().quit()

func _dirs_in_dir_absolute(path: String) -> Array:
	return Array(DirAccess.get_directories_at(path)).map(path.path_join)

func get_saves() -> Array:
	return (
		_dirs_in_dir_absolute(WorldSave.STOCK_WORLDS_PATH)
		+ _dirs_in_dir_absolute(WorldSave.USER_WORLDS_PATH)
	).map(WorldSave.new)
