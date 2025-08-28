extends MeshInstance3D

func _process(delta: float) -> void:
	# The illusion........!
	
	var cam = get_viewport().get_camera_3d()
	
	self.global_position.x = cam.global_position.x
	self.global_position.z = cam.global_position.z
