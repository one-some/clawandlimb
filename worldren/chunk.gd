extends MeshInstance3D

var chunk_pos: Vector3
var data = ChunkData.new()
@export var noise: Noise

func lazy_load_hack() -> void:
	var shader_mat: ShaderMaterial = material_override
	if not shader_mat.get_shader_parameter("textures"):
		var t2d_arr = Texture2DArray.new()
		print(State._hack_tile_images.map(func(x: Image): return x.get_format()))
		t2d_arr.create_from_images(State._hack_tile_images)
		shader_mat.set_shader_parameter("textures", t2d_arr)
	

func _ready() -> void:
	lazy_load_hack()

func generate() -> void:
	self.global_position = chunk_pos * ChunkData.CHUNK_SIZE
	
	for x in ChunkData.PADDED_SIZE:
		for y in ChunkData.PADDED_SIZE:
			for z in ChunkData.PADDED_SIZE:
				var local_pos = Vector3(x, y, z)
				var global_pos = (chunk_pos * ChunkData.CHUNK_SIZE) + local_pos
				var val = noise.get_noise_3dv(global_pos)
				var idx = data.get_index(local_pos)
				
				data.density[idx] = val - (global_pos.y / 10.0)
				
				var mat = 2 # Stone
				if global_pos.y > -3.0:
					mat = 1 # Grass
				elif global_pos.y > -5.0:
					mat = 0 # Dirt
				data.material[idx] = mat
	
	generate_mesh()

func generate_mesh() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
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
				
				var corner_densities = corner_positions.map(func(x): return data.density[data.get_index(x)])
				var corner_materials = corner_positions.map(func(x): return data.material[data.get_index(x)])
				
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
				var cell_colors = []
				var cell_uv2s = []
				var vertex_map = []
				vertex_map.resize(12)
				vertex_map.fill(-1)
				
				for i in range(12):
					if not (edge_mask & (1 << i)): continue
					var vertex_indices = [
						[0, 1],
						[1, 2],
						[2, 3],
						[3, 0],
						[4, 5],
						[5, 6],
						[6, 7],
						[7, 4],
						[0, 4],
						[1, 5],
						[2, 6],
						[3, 7]
					][i]
					
					var p0 = corner_positions[vertex_indices[0]]
					var p1 = corner_positions[vertex_indices[1]]
					var d0 = corner_densities[vertex_indices[0]]
					var d1 = corner_densities[vertex_indices[1]]
					var m0 = corner_materials[vertex_indices[0]]
					var m1 = corner_materials[vertex_indices[1]]
					
					
					var t = 0.5
					if d1 - d0:
						t = -d0 / (d1 - d0)
						
					var vertex_pos = p0.lerp(p1, t)
					cell_vertices.append(vertex_pos)
					cell_colors.append(Color(m0 / 255.0, m1 / 255.0, 0.0))
					cell_uv2s.append(Vector2(t, 0.0))
					
					vertex_map[i] = cell_vertices.size() - 1
				
				var triangles = MarchData.tri_table[index]
				var i = 0
				while triangles[i] != -1:
					for idx in [i, i + 2, i + 1]:
						st.set_color(cell_colors[vertex_map[triangles[idx]]])
						st.set_uv2(cell_uv2s[vertex_map[triangles[idx]]])
						st.add_vertex(cell_vertices[vertex_map[triangles[idx]]])
					i += 3
	st.generate_normals()
	self.mesh = st.commit()
