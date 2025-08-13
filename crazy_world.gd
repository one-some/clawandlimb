class_name ChunkManager extends Node3D

const Chunk = preload("res://worldren/chunk.tscn")
@onready var nav_region = $NavigationRegion3D
var ids = []
var world_aabb = AABB()
var chunks_left = 0
var chunks = {}

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

func gen_nav() -> void:
	# Nav stuff
	var nav_mesh = NavigationMesh.new()
	nav_region.navigation_mesh = nav_mesh
	
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	# TODO: Change source mode for performance...?
	
	var aabb_size = Vector3(ChunkData.CHUNK_SIZE, ChunkData.CHUNK_SIZE, ChunkData.CHUNK_SIZE)
	var aabb_pos = self.global_position# - Vector3(0, aabb_size.y / 2.0, 0)
	var baking_aabb = AABB(aabb_pos, aabb_size)
	baking_aabb = baking_aabb.grow(1.0)
	nav_mesh.filter_baking_aabb = baking_aabb
	
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nav_mesh.geometry_source_group_name = "NavigationObstacle"
	nav_mesh.border_size = 1.0
	
	nav_region.bake_navigation_mesh()
	await nav_region.bake_finished

func load_tiles() -> void:
	var path = "res://tex/tiles/"
	var dir = DirAccess.open(path)
	
	for file in dir.get_files():
		if not file.ends_with(".png"): continue
		var image = ResourceLoader.load(path + file).get_image()
		State._hack_tile_images.append(image)

func _ready() -> void:
	# Does this suck. Let me know.
	State.chunk_manager = self
	
	load_tiles()
	
	var positions = []
	
	for x in range(-2, 2):
		for y in range(-2, 2):
			for z in range(-2, 2):
				positions.append(Vector3(x, y, z))
	
	var origin = Vector3(0, 0, 0)
	positions.sort_custom(func(a, b): return b.distance_to(origin) > a.distance_to(origin))
	#positions = positions.slice(0, 10)
	
	chunks_left = positions.size()
	
	var first_pos = positions[0] * ChunkData.CHUNK_SIZE
	world_aabb = AABB(first_pos, Vector3.ZERO)
	
	for pos in positions:
		var chunk = Chunk.instantiate()
		chunks[pos] = chunk
		chunk.mesh_generated.connect(_on_chunk_mesh_generated.bind(chunk))
		self.add_child(chunk)
		
		world_aabb = world_aabb.merge(AABB(
			pos * ChunkData.CHUNK_SIZE,
			Vector3(
				ChunkData.CHUNK_SIZE,
				ChunkData.CHUNK_SIZE,
				ChunkData.CHUNK_SIZE
			)
		))
		
		ids.append(WorkerThreadPool.add_task(chunk.generate.bind(pos)))

func _on_chunk_mesh_generated(chunk: MeshInstance3D) -> void:
	chunks_left -= 1
	
	print("%s chunks left" % chunks_left)
	
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

func _exit_tree() -> void:
	for id in ids:
		WorkerThreadPool.wait_for_task_completion(id)
