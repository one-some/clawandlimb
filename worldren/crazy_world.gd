class_name ChunkManager extends Node3D

const ChunkMaterial = preload("res://worldren/chunk_material.tres")
const TreeRes = preload("res://tree.tscn")
const RockRes = preload("res://rock.tscn")
const CopperRes = preload("res://copper_rock.tscn")

const SEA_LEVEL = 12 + 0.9
const GROW_CHUNKS = 4

@export var biome_humidity: Noise
@export var biome_temperature: Noise

@onready var nav_region = $NavigationRegion3D

static var CHUNK_SIZE: int = VoxelMesh.get_chunk_size()
static var PADDED_SIZE: int = CHUNK_SIZE + 1

var ids = []
var world_aabb = AABB()

var chunks_left = 0
static var chunks = {}
static var finished_chunks = []
var chunk_threads = {}

func _ready() -> void:
	# Does this suck. Let me know.
	load_tiles()
	State.chunk_manager = self
	
	$/root/Main/Water.position.y = SEA_LEVEL
	VoxelMesh.set_sea_level(SEA_LEVEL)
	
	Signals.load_save.connect(func(save: WorldSave):
		VoxelMesh.set_worldgen_algorithm(save.get_worldgen_algorithm())
		VoxelMesh.set_seed(save.get_seed_int())
		
		seed(save.get_seed_int())
		var pos = VoxelMesh.find_a_good_place_to_spawn_that_player_guy()
		
		Signals.tp_player.emit(pos + Vector3(0, 2.0, 0))
		generate_around(pos, GROW_CHUNKS)
	)
	
	print("Chunk manager ready")


func _process(delta: float) -> void:
	var cam = get_viewport().get_camera_3d()
	generate_around(cam.global_position, GROW_CHUNKS)

static func pos_to_chunk_pos(pos: Vector3) -> Vector3:
	return (pos / CHUNK_SIZE).floor()

func clamp_vec3(v: Vector3, min_val: float, max_val: float) -> Vector3:
	return Vector3(
		clampf(v.x, min_val, max_val),
		clampf(v.y, min_val, max_val),
		clampf(v.z, min_val, max_val)
	)

func delete_area(area: AABB, soft_delete: bool) -> void:
	print(area)
	
	var start = area.position
	var end = start + area.size
	
	var start_chunk = (start / CHUNK_SIZE).floor()
	var end_chunk = (end / CHUNK_SIZE).ceil()
	
	for chunk_x in range(start_chunk.x, end_chunk.x + 1):
		for chunk_y in range(start_chunk.y, end_chunk.y + 1):
			for chunk_z in range(start_chunk.z, end_chunk.z + 1):
				var chunk_pos = Vector3(chunk_x, chunk_y, chunk_z)
				
				if chunk_pos not in finished_chunks:
					print("TODO: Generatte")
					continue
				
				var chunk = chunks[chunk_pos]
				var chunk_origin = chunk_pos * CHUNK_SIZE
				var chunk_far_bound = chunk_origin + Vector3(
					CHUNK_SIZE,
					CHUNK_SIZE,
					CHUNK_SIZE,
				)
		
				var intersects = (
					start.x < chunk_far_bound.x and end.x > chunk_origin.x and
					start.y < chunk_far_bound.y and end.y > chunk_origin.y and
					start.z < chunk_far_bound.z and end.z > chunk_origin.z
				)
				if not intersects:
					continue
				
				# Get the position of the start relative to the chunks global offset, and clamp it between 0 and CHUNK_SIZE
				
				var big_chunk_chunk_start = clamp_vec3(start - chunk_origin, 0.0, PADDED_SIZE)
				var big_chunk_chunk_end = clamp_vec3(end - chunk_origin, 0.0, PADDED_SIZE)
				
				var zone_aabb = AABB(big_chunk_chunk_start, big_chunk_chunk_end - big_chunk_chunk_start)
				chunk.delete_area(zone_aabb, soft_delete)

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
	var chunk_origin = pos_to_chunk_pos(global_origin)
	
	var positions = []
	for x in range(-extent, extent):
		for y in range(-extent, extent):
			for z in range(-extent, extent):
				positions.append(chunk_origin + Vector3(x, y, z))
	
	positions = positions.filter(func(x): return x not in chunks)
	if not positions: return
	
	positions.sort_custom(func(a, b): return b.distance_to(chunk_origin) > a.distance_to(chunk_origin))
	#positions = positions.slice(0, 10)
	
	chunks_left = positions.size()
	print("Generating %s chunks :3" % chunks_left)
	
	if not world_aabb:
		var first_pos = pos_to_chunk_pos(positions[0])
		world_aabb = AABB(first_pos, Vector3.ZERO)
	
	for pos in positions:
		var chunk = VoxelMesh.new()
		self.add_child(chunk)
		
		chunk.set_layer_mask_value(2, true)
		
		chunk.material_override = ChunkMaterial
		chunk.material_override.set_shader_parameter("textures", State._hack_t2d)
		
		chunk.set_pos(pos)
		
		chunks[pos] = chunk
		chunk.finished_mesh_generation.connect(func(first_time: bool):
			_on_chunk_mesh_generated(chunk, pos, first_time)
		)
		
		world_aabb = world_aabb.merge(AABB(
			pos * CHUNK_SIZE,
			Vector3(
				CHUNK_SIZE,
				CHUNK_SIZE,
				CHUNK_SIZE
			)
		))
		
		var task_id = WorkerThreadPool.add_task(func():
			if not chunk: return
			chunk.generate_chunk_data()
			chunk.generate_mesh()
		)
		chunk_threads[chunk] = task_id

func should_place_stuff() -> bool:
	return State.active_save.get_worldgen_algorithm() not in [VoxelMesh.WORLDGEN_FLAT]

func _on_chunk_mesh_generated(chunk: VoxelMesh, chunk_pos: Vector3, first_time: bool) -> void:
	if chunk in chunk_threads:
		var task_id = chunk_threads[chunk]
		WorkerThreadPool.wait_for_task_completion(task_id)
		chunk_threads.erase(chunk)
	
	var chunk_center = (chunk_pos + Vector3(0.5, 0.5, 0.5)) * CHUNK_SIZE
	#print("Sampling at chunk center: ", VoxelMesh.sample_noise(chunk_center))
	
	var body: StaticBody3D
	for child in chunk.get_children():
		if child.name != "ChunkCollider": continue
		body = child
		break
	
	if not body:
		body = StaticBody3D.new()
		body.name = "ChunkCollider"
		body.add_to_group("NavigationObstacle")
		body.set_collision_layer_value(5, true)
		chunk.add_child(body)
		body.add_child(CollisionShape3D.new())
	
	assert(body)
	
	var collision_shape: CollisionShape3D = body.get_child(0)
	collision_shape.shape = chunk.mesh.create_trimesh_shape()
	
	# Place things
	if first_time and should_place_stuff():
		for local_thing_pos in chunk.get_resource_position_candidates():
			local_thing_pos.y -= 0.25
			
			var global_thing_pos = local_thing_pos + chunk.global_position
			if global_thing_pos.y < SEA_LEVEL + 0.75: continue
			
			var biome = VoxelMesh.get_biome(Vector2(global_thing_pos.x, global_thing_pos.z))
			
			var thing: Node3D = null
			var rand = randf()
			
			match biome:
				VoxelMesh.BIOME_GRASS:
					if rand < 0.1:
						thing = CopperRes.instantiate()
					elif rand < 0.3:
						thing = RockRes.instantiate()
					else:
						thing = TreeRes.instantiate()
				VoxelMesh.BIOME_TUNDRA:
					if rand < 0.4:
						thing = TreeRes.instantiate()
					elif rand < 0.7:
						thing = RockRes.instantiate()
				
			if not thing: continue
			
			thing.position = local_thing_pos
			thing.rotation.y = randf() * PI * 2
			chunk.add_child(thing)
	
		# TODO: How to interact with first_time???
		chunks_left -= 1
		#print("%s chunk5s left" % chunks_left)
		
		if not chunks_left:
			bake_world_nav(world_aabb.grow(1.0))
	
	finished_chunks.push_back(chunk_pos)
	Signals.chunk_generated.emit(chunk, chunk_pos)

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
		
	nav_region.bake_navigation_mesh() 
		
	await nav_region.bake_finished
	print("World navigation bake finished!")

func update_chunk_collision(chunk_pos: Vector2) -> void:
	print("LOL NOT ACTUALLY UPDATYING (anything)")

func _exit_tree() -> void:
	# If something terrible happens...
	#for task_id in chunk_threads.values():
	#WorkerThreadPool.wait_for_task_completion(task_id)
	# Ok actually this just freezes the game on close. I'll
	pass
	# on that.
