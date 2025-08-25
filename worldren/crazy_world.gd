class_name ChunkManager extends Node3D

const ChunkMaterial = preload("res://worldren/chunk_material.tres")
const TreeRes = preload("res://tree.tscn")
const RockRes = preload("res://rock.tscn")
const CopperRes = preload("res://copper_rock.tscn")

const SEA_LEVEL = 19.0

@export var biome_humidity: Noise
@export var biome_temperature: Noise

@onready var nav_region = $NavigationRegion3D

var seed = randi() * 09142008 * 1000

var ids = []
var world_aabb = AABB()

var chunks_left = 0
static var chunks = {}
static var finished_chunks = []
var chunk_threads = {}
var first_chunk_generated = false

func get_chunk_pos_from_global_pos(pos: Vector3) -> Vector3:
	return (pos / ChunkData.CHUNK_SIZE).floor()

func delete_area(area: AABB) -> void:
	print(area)
	
	var start = area.position
	var end = start + area.size
	
	var start_chunk = (start / ChunkData.CHUNK_SIZE).floor()
	var end_chunk = (end / ChunkData.CHUNK_SIZE).ceil()
	
	for chunk_x in range(start_chunk.x, end_chunk.x + 1):
		for chunk_y in range(start_chunk.x, end_chunk.x + 1):
			for chunk_z in range(start_chunk.x, end_chunk.x + 1):
				var chunk_pos = Vector3(chunk_x, chunk_y, chunk_z)
				
				if chunk_pos not in finished_chunks:
					print("TODO: Generatte")
					continue
				
				var chunk = chunks[chunk_pos]
				var chunk_origin = chunk_pos * ChunkData.CHUNK_SIZE
				var chunk_far_bound = chunk_origin + Vector3(
					ChunkData.CHUNK_SIZE,
					ChunkData.CHUNK_SIZE,
					ChunkData.CHUNK_SIZE,
				)
		
				if (
					start.x >= chunk_far_bound.x
					or start.y >= chunk_far_bound.y
					or start.z >= chunk_far_bound.z
				):
					continue
				
				if (
					end.x <= chunk_origin.x
					or end.y <= chunk_origin.y
					or end.z <= chunk_origin.z
				):
					continue
				
				# Get the position of the start relative to the chunks global offset, and clamp it between 0 and CHUNK_SIZE
				
				var big_chunk_chunk_start = Vector3(
					(start - chunk_origin).clampf(0.0, ChunkData.PADDED_SIZE)
				)
				
				var big_chunk_chunk_end = Vector3(
					(end - chunk_origin).clampf(0.0, ChunkData.PADDED_SIZE)
				)
				
				var zone_aabb = AABB(big_chunk_chunk_start, big_chunk_chunk_end - big_chunk_chunk_start)
				chunk.delete_area(zone_aabb)

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
		var first_pos = positions[0] * ChunkData.CHUNK_SIZE
		world_aabb = AABB(first_pos, Vector3.ZERO)
	
	for pos in positions:
		var chunk = VoxelMesh.new()
		self.add_child(chunk)
		
		chunk.set_layer_mask_value(2, true)
		
		chunk.material_override = ChunkMaterial
		chunk.material_override.set_shader_parameter("textures", State._hack_t2d)
		
		chunk.set_seed(seed)
		chunk.set_pos(pos)
		chunk.set_sea_level(SEA_LEVEL)
		
		chunks[pos] = chunk
		chunk.finished_mesh_generation.connect(_on_chunk_mesh_generated.bind(chunk))
		
		world_aabb = world_aabb.merge(AABB(
			pos * ChunkData.CHUNK_SIZE,
			Vector3(
				ChunkData.CHUNK_SIZE,
				ChunkData.CHUNK_SIZE,
				ChunkData.CHUNK_SIZE
			)
		))
		
		var task_id = WorkerThreadPool.add_task(func():
			if not chunk: return
			chunk.generate_chunk_data()
			(func():
				if not chunk: return
				chunk.generate_mesh()
				
				for thing_pos in chunk.get_resource_position_candidates():
					var biome = chunk.get_biome(Vector2(thing_pos.x, thing_pos.z))
					thing_pos.y -= 0.25
					
					if thing_pos.y + chunk.global_position.y < SEA_LEVEL + 0.75: continue
					
					var thing: Node3D
					var rand = randf()
					
					if biome == VoxelMesh.BIOME_GRASS:
						if rand < 0.1:
							thing = CopperRes.instantiate()
						elif rand < 0.3:
							thing = RockRes.instantiate()
						else:
							thing = TreeRes.instantiate()
					elif biome == VoxelMesh.BIOME_TUNDRA:
						if rand < 0.3:
							thing = RockRes.instantiate()
						elif rand < 0.7:
							thing = TreeRes.instantiate()
					
					if not thing: continue
							
					thing.position = thing_pos
					thing.rotation.y = randf() * PI * 2
					chunk.add_child(thing)
				
				finished_chunks.push_back(pos)
				Signals.chunk_generated.emit(chunk, pos)
				
			).call_deferred()
		)
		chunk_threads[chunk] = task_id
	
	
func _ready() -> void:
	# Does this suck. Let me know.
	load_tiles()
	State.chunk_manager = self
	
	$/root/Main/Water.position.y = SEA_LEVEL
	
	generate_around(Vector3.ZERO, 4)

func _on_chunk_mesh_generated(chunk: VoxelMesh) -> void:
	# FIXME: Why isn't this consolidated with the big call_deferred thing..?
	if chunk in chunk_threads:
		var task_id = chunk_threads[chunk]
		WorkerThreadPool.wait_for_task_completion(task_id)
		chunk_threads.erase(chunk)
	
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
	
	if not first_chunk_generated:
		var faces = chunk.mesh.get_faces()
		if faces:
			print("LOL Teleporting")
			first_chunk_generated = true
			Signals.tp_player.emit(faces[0] + Vector3(0, 40.0, 0))
	
	chunks_left -= 1
	#print("%s chunk5s left" % chunks_left)
	
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
		
	nav_region.bake_navigation_mesh() 
		
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
