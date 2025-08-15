extends MeshInstance3D

signal mesh_generated

const tree_res = preload("res://tree.tscn")
const rock_res = preload("res://rock.tscn")

var chunk_pos: Vector3
var data = ChunkData.new()
var body: StaticBody3D

var tree_grid = {}

@export var low_noise: FastNoiseLite
@export var high_noise: FastNoiseLite
@export var rough_noise: FastNoiseLite

func lazy_load_hack() -> void:
	if not low_noise.seed:
		@warning_ignore("narrowing_conversion")
		low_noise.seed = (randf() -0.5) * 2000000.0
		@warning_ignore("narrowing_conversion")
		high_noise.seed = (randf() - 0.5) * 2000000.0
		@warning_ignore("narrowing_conversion")
		rough_noise.seed = (randf() - 0.5) * 2000000.0
	
	var shader_mat: ShaderMaterial = material_override
	if not shader_mat.get_shader_parameter("textures"):
		shader_mat.set_shader_parameter("textures", State._hack_t2d)

func snip_middle(n: float, middle: float) -> float:
	if abs(n) < middle:
		return 0.0
	
	if n >= 0:
		return n - middle
	return n + middle

func sample_noise(pos: Vector3) -> float:
	var out = -pos.y
	
	out += low_noise.get_noise_3dv(pos * 7.0) * 2.0
	
	var low_valley_guage = low_noise.get_noise_3dv(pos * 10.0)
	low_valley_guage = snip_middle(low_valley_guage, 0.3)
	out += low_noise.get_noise_3dv(pos) * 200.0 * low_valley_guage
	
	
	#var high = high_noise.get_noise_3dv(pos) * 5.0
	#var rough = rough_noise.get_noise_3dv(pos) * 0.05
	
	return out

func _ready() -> void:
	lazy_load_hack()

@warning_ignore("shadowed_variable")
func generate(chunk_pos: Vector3) -> void:
	self.chunk_pos = chunk_pos
	self.set_deferred("global_position", chunk_pos * ChunkData.CHUNK_SIZE)
	
	var candidate_tree_positions = []
	
	for x in ChunkData.PADDED_SIZE:
		for y in ChunkData.PADDED_SIZE:
			for z in ChunkData.PADDED_SIZE:
				var local_pos = Vector3(x, y, z)
				var global_pos = (chunk_pos * ChunkData.CHUNK_SIZE) + local_pos
				
				var val = sample_noise(global_pos)
				var idx = data.get_index(local_pos)
				
				var density = val
				data.density[idx] = density
				
				var mat = 2 # Stone
				if density < 0.4:
					mat = 1 # Grass
				elif density < 1.8:
					mat = 0 # Stone
				data.material[idx] = mat
				
				if mat == 1 and density < 0.05 and density > -0.01 and randf() < 0.1:
					var tree_cell = (global_pos / 4.0).round()
					if not tree_cell in tree_grid:
						tree_grid[tree_cell] = true
						candidate_tree_positions.append(global_pos)

	
	for pos in candidate_tree_positions:
		var thing: Node3D
		if randf() < 0.3:
			thing = rock_res.instantiate()
		else:
			thing = tree_res.instantiate()
		
		thing.position = pos
		thing.rotation.y = randf() * PI * 2
		self.add_child.call_deferred(thing)
	
	generate_mesh()

func generate_mesh() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	
	var corner_densities = []
	corner_densities.resize(8)
	var corner_materials = []
	corner_materials.resize(8)
	var vertex_map = []
	vertex_map.resize(12)
	var cell_vertices = []
	cell_vertices.resize(12)
	var vertex_data_map = []
	vertex_data_map.resize(12)
	
	for x in ChunkData.CHUNK_SIZE:
		for y in ChunkData.CHUNK_SIZE:
			for z in ChunkData.CHUNK_SIZE:
				var corner_positions = [
					Vector3(x, y, z),
					Vector3(x + 1, y, z),
					Vector3(x + 1, y, z + 1),
					Vector3(x, y, z + 1),
					Vector3(x, y + 1, z),
					Vector3(x + 1, y + 1, z),
					Vector3(x + 1, y + 1, z + 1),
					Vector3(x, y + 1, z + 1),
				]
				
				corner_densities.clear()
				corner_materials.clear()
				
				for corner in corner_positions:
					var idx = data.get_index(corner)
					corner_densities.append(data.density[idx])
					corner_materials.append(data.material[idx])
				
				# TODO: Check for destroyed corners.....
				
				var index = 0
				for i in range(corner_densities.size()):
					if corner_densities[i] <= 0.0: continue
					index |= 1 << i
				
				if index == 0 or index == 255:
					# All surface / air
					continue
				
				var edge_mask = MarchData.edge_table[index]
				cell_vertices.clear()
				vertex_data_map.clear()
				vertex_map.fill(-1)
				
				for i in range(12):
					if not (edge_mask & (1 << i)): continue
					var vertex_indices = [
						[0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6],
						[6, 7], [7, 4], [0, 4], [1, 5], [2, 6], [3, 7]
					][i]
					
					var p0 = corner_positions[vertex_indices[0]]
					var p1 = corner_positions[vertex_indices[1]]
					var d0 = corner_densities[vertex_indices[0]]
					var d1 = corner_densities[vertex_indices[1]]
					
					var t = 0.5
					if d1 - d0:
						t = -d0 / (d1 - d0)
						
					var vertex_pos = p0.lerp(p1, t)
					cell_vertices.append(vertex_pos)
					
					var rel_pos = vertex_pos - Vector3(x, y, z)
					
					var weights = [
						(1.0 - rel_pos.x) * (1.0 - rel_pos.y) * (1.0 - rel_pos.z),
						rel_pos.x * (1.0 - rel_pos.y) * (1.0 - rel_pos.z),
						rel_pos.x * (1.0 - rel_pos.y) * rel_pos.z,
						(1.0 - rel_pos.x) * (1.0 - rel_pos.y) * rel_pos.z,
						(1.0 - rel_pos.x) * rel_pos.y * (1.0 - rel_pos.z),
						rel_pos.x * rel_pos.y * (1.0 - rel_pos.z),
						rel_pos.x * rel_pos.y * rel_pos.z,
						(1.0 - rel_pos.x) * rel_pos.y * rel_pos.z,
					]
					
					var top_mats = [-1, -1, -1, -1]
					var top_weights = [0.0, 0.0, 0.0, 0.0]
					
					var unique_mats = {}
					for j in range(8):
						var mat_id = corner_materials[j]
						if mat_id not in unique_mats:
							unique_mats[mat_id] = 0.0
						unique_mats[mat_id] += weights[j]
					
					for mat_id in unique_mats:
						var weight = unique_mats[mat_id]
						for k in range(4):
							if weight <= top_weights[k]: continue
							for l in range(3, k, -1):
								top_weights[l] = top_weights[l - 1]
								top_mats[l] = top_mats[l - 1]
							top_weights[k] = weight
							top_mats[k] = mat_id
							break
					
					var final_ids = Vector4(top_mats[0], top_mats[1], top_mats[2], top_mats[3])
					var final_weights = Vector4(top_weights[0], top_weights[1], top_weights[2], top_weights[3])

					var total_weight = final_weights.x + final_weights.y + final_weights.z + final_weights.w
					if total_weight > 0.0:
						final_weights /= total_weight
					
					vertex_data_map.append({
						"ids": final_ids,
						"weights": final_weights
					})
					
					vertex_map[i] = cell_vertices.size() - 1
				
				var starter = MarchData.tri_subarray_lengths[index]
				var ender = MarchData.tri_subarray_lengths[index + 1]
				var triangles = MarchData.tri_edge_indices.slice(starter, ender)
				
				var i = 0
				while i < triangles.size():
					for idx in [i, i + 2, i + 1]:
						# HACK: Godot literally cannot handle reading 2d arrays
						# multithreaded and just returns garbage data sometimes.
						# The most we can do is just render nothing or garbage
						# geometry instead of crashing
						var vertex_index_in_cell = vertex_map[triangles[idx]]
						@warning_ignore("shadowed_variable")
						var data = vertex_data_map[vertex_index_in_cell]
						
						st.set_color(Color(data.weights.x, data.weights.y, data.weights.z, data.weights.w))
						st.set_custom(0, Color(data.ids.x, data.ids.y, data.ids.z, data.ids.w))
						st.add_vertex(cell_vertices[vertex_index_in_cell])
					i += 3
	st.generate_normals()
	#st.generate_tangents()
	(func():
		self.mesh = st.commit()
		
		if body:
			body.name = "_DIE_DIE_DIE"
			body.queue_free()
			body = null
		
		body = StaticBody3D.new()
		self.add_child(body)
		
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = self.mesh.create_trimesh_shape()
		body.add_child(collision_shape)
		
		body.name = "ChunkCollider"
		body.add_to_group("NavigationObstacle")
		body.set_collision_layer_value(5, true)
		assert(body)
		
		mesh_generated.emit()
	).call_deferred()
