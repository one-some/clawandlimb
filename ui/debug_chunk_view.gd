extends Node3D

@export var chunk_border_material: StandardMaterial3D
var camera_chunk = null

func _input(event: InputEvent) -> void:
	if event is not InputEventKey: return
	if not event.pressed: return
	if not event.is_action("debug_chunk_bounds"): return
	self.visible = not self.visible

func _process(delta: float) -> void:
	if not self.visible: return
	
	var cam = get_viewport().get_camera_3d()
	var chunk_pos = ChunkManager.pos_to_chunk_pos(cam.global_position)
	
	if chunk_pos == camera_chunk: return
	
	camera_chunk = chunk_pos
	roll_it_back(chunk_pos)

func roll_it_back(chunk_pos: Vector3) -> void:
	assert(chunk_pos == chunk_pos.round())
	
	for child in self.get_children():
		child.queue_free()
	
	for x in range(-5, 5):
		for z in range(-5, 5):
			var mi = MeshInstance3D.new()
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.mesh = BoxMesh.new()
			mi.mesh.size = Vector3(0.05, 1000.0, 0.05)
			mi.position = (chunk_pos + Vector3(x, 0, z)) * ChunkManager.CHUNK_SIZE
			mi.mesh.material = chunk_border_material
			self.add_child(mi)
