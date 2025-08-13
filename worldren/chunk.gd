extends MeshInstance3D

signal mesh_generated

const tree_res = preload("res://tree.tscn")

var chunk_pos: Vector3
var data = ChunkData.new()
var body: StaticBody3D

@export var low_noise: FastNoiseLite
@export var high_noise: FastNoiseLite
@export var rough_noise: FastNoiseLite

func lazy_load_hack() -> void:
	if not low_noise.seed:
		low_noise.seed = (randf() -0.5) * 2000000
		high_noise.seed = (randf() - 0.5) * 2000000
		rough_noise.seed = (randf() - 0.5) * 2000000
	
	var shader_mat: ShaderMaterial = material_override
	if not shader_mat.get_shader_parameter("textures"):
		var t2d_arr = Texture2DArray.new()
		print(State._hack_tile_images.map(func(x: Image): return x.get_format()))
		t2d_arr.create_from_images(State._hack_tile_images)
		shader_mat.set_shader_parameter("textures", t2d_arr)

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
				
				if density < 0.05 and density > -0.01 and randf() < 0.1:
					var add = true
					for pos in candidate_tree_positions:
						if pos.distance_to(global_position) > 1.0: continue
						add = false
						break
					
					if add:
						candidate_tree_positions.append(global_position)
				
				var mat = 2 # Stone
				if density < 0.4:
					mat = 1 # Grass
				elif density < 1.8:
					mat = 0 # Stone
				data.material[idx] = mat
	
	print(len(candidate_tree_positions))
	
	for pos in candidate_tree_positions:
		var tree = tree_res.instantiate()
		tree.position = pos
		tree.rotation.y = randf() * PI * 2
		self.add_child.call_deferred(tree)
	
	generate_mesh()

func generate_mesh() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_custom_format(0, SurfaceTool.CUSTOM_RGBA_FLOAT)
	
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
				
				var corner_densities = []
				var corner_materials = []
				
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
				var cell_vertices = []
				var vertex_data_map = []
				var vertex_map = []
				vertex_map.resize(12)
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
					
					var mat_weights = {}
					for j in range(8):
						var mat_id = corner_materials[j]
						if mat_id not in mat_weights:
							mat_weights[mat_id] = 0.0
						mat_weights[mat_id] += weights[j]
					
					var sorted_mats = mat_weights.keys()
					sorted_mats.sort_custom(func(a, b): return mat_weights[a] > mat_weights[b])
					
					var final_ids = Vector4.ZERO
					var final_weights = Vector4.ZERO
					var total_weight = 0.0
					
					var num_mats = min(sorted_mats.size(), 4)
					for j in range(num_mats):
						var mat_id = sorted_mats[j]
						var weight = mat_weights[mat_id]
						final_ids[j] = float(mat_id)
						final_weights[j] = weight
						total_weight += weight
					
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
		
		self.create_trimesh_collision()
		
		for c in get_children():
			if c is not StaticBody3D: continue
			if c == body: continue
			body = c
			c.name = "ChunkCollider"
			c.add_to_group("NavigationObstacle")
			c.set_collision_layer_value(5, true)
			break
		
		mesh_generated.emit()
	).call_deferred()
