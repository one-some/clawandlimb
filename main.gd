extends Node3D

@onready var sun = $DirectionalLight3D
var time_seconds = 12 * 60 * 60

func _process(delta: float) -> void:
	time_seconds += 2.0
	
	var hours = fmod(time_seconds / 60.0 / 60.0, 24.0)
	var sun_norm = fmod(hours + 8, 24.0) / 24.0
	sun.rotation.x = sun_norm * 2 * PI
	
	var bad_guys_work = hours > 20 and hours < 8
	for guy in get_tree().get_nodes_in_group("Enemy"):
		guy.process_mode = PROCESS_MODE_INHERIT if bad_guys_work else PROCESS_MODE_DISABLED
		guy.visible = bad_guys_work
