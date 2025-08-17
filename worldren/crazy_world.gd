class_name ChunkManager extends Node3D

#const Chunk = preload("res://worldren/chunk.tscn")
@onready var nav_region = $NavigationRegion3D
var ids = []
var world_aabb = AABB()

var chunks_left = 0
var chunks = {}
var chunk_threads = {}
var first_chunk_generated = false

func get_chunk_pos_from_global_pos(pos: Vector3) -> Vector3:
	return (pos / ChunkData.CHUNK_SIZE).floor()

func set_density_global(pos: Vector3, density: float) -> Array:
	var modified = []
	var main_chunk_pos = get_chunk_pos_from_global_pos(pos)
	
	for dx in range(0, -2, -1):
		for dy in range(0, -2, -1):
			for dz in range(0, -2, -1):
				var chunk_pos = main_chunk_pos + Vector3(dx, dy, dz)
				if chunk_pos not in chunks: continue
				
				var chunk = chunks[chunk_pos]
				var data: ChunkData = chunk.data
				var global_origin = chunk_pos * ChunkData.CHUNK_SIZE
				var local_pos = pos - global_origin
				
				if local_pos.x < 0: continue
				if local_pos.y < 0: continue
				if local_pos.z < 0: continue
				if local_pos.x >= ChunkData.PADDED_SIZE: continue
				if local_pos.y >= ChunkData.PADDED_SIZE: continue
				if local_pos.z >= ChunkData.PADDED_SIZE: continue
				
				data.density[data.get_index(local_pos)] = density
				
				if chunk_pos not in modified:
					modified.append(chunk_pos)
	
	return modified

func load_tiles() -> void:
	var path = "res://tex/tiles/"
	var dir = DirAccess.open(path)
	var file_names = []
	
	for file_name in dir.get_files():
		file_name = file_name.replace(".import", "")
		if file_name in file_names: continue
		if not file_name.ends_with(".png"): continue
		file_names.append(file_name)
		
	file_names.sort()
	print(file_names)
	
	var t2d_arr = Texture2DArray.new()
	t2d_arr.create_from_images(file_names.map(func(file_name):
		return ResourceLoader.load(path + file_name).get_image()
	))
	State._hack_t2d = t2d_arr

func generate_around(global_origin: Vector3, extent: int = 3) -> void:
	var chunk_origin = get_chunk_pos_from_global_pos(global_origin)
	
	var positions = []
	for x in range(-extent, extent):
		for y in range(-2, 2):
			for z in range(-extent, extent):
				positions.append(chunk_origin + Vector3(x, y, z))
	
	positions = positions.filter(func(x): return x not in chunks)
	if not positions: return
	
	positions.sort_custom(func(a, b): return b.distance_to(chunk_origin) > a.distance_to(chunk_origin))
	#positions = positions.slice(0, 10)
	
	chunks_left = positions.size()
	print("Generating %s chunks :3" % chunks_left)
	
	if not world_aabb:
		var first_pos = positions[0] * ChunkData.CHUNK_SIZE
		world_aabb = AABB(first_pos, Vector3.ZERO)
	
	for pos in positions:
		var chunk = VoxelMesh.new()
		self.add_child(chunk)
		chunk.set_pos(pos)
		chunks[pos] = chunk
		#chunk.mesh_generated.connect(_on_chunk_mesh_generated.bind(chunk))
		
		world_aabb = world_aabb.merge(AABB(
			pos * ChunkData.CHUNK_SIZE,
			Vector3(
				ChunkData.CHUNK_SIZE,
				ChunkData.CHUNK_SIZE,
				ChunkData.CHUNK_SIZE
			)
		))
		
		#chunk.generate_chunk_data()
		#chunk.generate_mesh()
		var task_id = WorkerThreadPool.add_task(func():
			chunk.generate_chunk_data()
			chunk.generate_mesh()
		)
		chunk_threads[chunk] = task_id
	

func _ready() -> void:
	# Does this suck. Let me know.
	load_tiles()
	State.chunk_manager = self
	
	generate_around(Vector3.ZERO, 12)

func _on_chunk_mesh_generated(chunk: MeshInstance3D) -> void:
	var task_id = chunk_threads[chunk]
	WorkerThreadPool.wait_for_task_completion(task_id)
	
	if not first_chunk_generated:
		var faces = chunk.mesh.get_faces()
		if faces:
			print("LOL")
			first_chunk_generated = true
			Signals.tp_player.emit(faces[0] + Vector3(0, 40.0, 0))
	
	chunks_left -= 1
	#print("%s chunks left" % chunks_left)
	
	if not chunks_left:
		bake_world_nav(world_aabb.grow(1.0))

func bake_world_nav(aabb: AABB) -> void:
	var nav_mesh = NavigationMesh.new()
	nav_mesh.cell_size = 0.25
	nav_mesh.agent_height = 2.0
	nav_mesh.agent_radius = 0.5
	
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nav_mesh.geometry_source_group_name = "NavigationObstacle"
	nav_mesh.filter_baking_aabb = world_aabb
	nav_region.navigation_mesh = nav_mesh
		
	nav_region.bake_navigation_mesh(false) 
		
	await nav_region.bake_finished
	print("World navigation bake finished!")


func _on_chunk_gen_timeout() -> void:
	var cam = get_viewport().get_camera_3d()
	generate_around(cam.global_position, 3)

func update_chunk_collision(chunk_pos: Vector2) -> void:
	print("LOL NOT ACTUALLY UPDATYING (anything)")

func _exit_tree() -> void:
	# If something terrible happens...
	#for task_id in chunk_threads.values():
	#WorkerThreadPool.wait_for_task_completion(task_id)
	# Ok actually this just freezes the game on close. I'll
	pass
	# on that.
