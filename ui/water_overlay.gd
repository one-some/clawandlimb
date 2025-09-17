extends ColorRect

func _process(delta: float) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	self.visible = cam.global_position.y < ChunkManager.SEA_LEVEL
