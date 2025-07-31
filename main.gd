extends Node3D

@onready var sun = $DirectionalLight3D
var time_seconds = 12 * 60 * 60

func _process(delta: float) -> void:
	time_seconds += 0.2
	
	var hours = fmod(time_seconds / 60.0 / 60.0, 24.0)
	var sun_norm = fmod(hours + 8, 24.0) / 24.0
	sun.rotation.x = sun_norm * 2 * PI
	
	print(time_seconds)
	
