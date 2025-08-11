extends MeshInstance3D

var data = ChunkData.new()
@export var noise: Noise

func _ready() -> void:
	generate()
	generate_mesh()

func generate() -> void:
	for x in ChunkData.CHUNK_SIZE:
		for y in ChunkData.CHUNK_SIZE:
			for z in ChunkData.CHUNK_SIZE:
				var idx = data.get_index(Vector3(x, y, z))
				var val = noise.get_noise_3d(x, y, z)
				if y > 5: val = 0.0
				
				data.density[idx] = val
				data.material[idx] = 1

func generate_mesh() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in ChunkData.CHUNK_SIZE - 1:
		for y in ChunkData.CHUNK_SIZE - 1:
			for z in ChunkData.CHUNK_SIZE - 1:
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
				
				# TODO: Check for destroyed corners.....
				
				var index = 0
				for i in range(corner_densities.size()):
					print(i, "-", corner_positions[i])
					if corner_densities[i] <= 0.0: continue
					index |= 1 << i
				
				if index == 0 or index == 255:
					# All surface / air
					continue
				
				var edge_mask = MarchData.edge_table[index]
				var vertices = []
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
					var t = (0.0 - d0) / (d1 - d0)
					vertices.append(p0.lerp(p1, t))
				
				var edges = MarchData.tri_table[index]
				var i = 0
				while edges[i] != -1:
					var vertex = Vector3(edges[i], edges[i + 1], edges[i + 2])
					st.set_color(Color.RED)
					st.add_vertex(vertex)
					i += 3
	st.commit(mesh)
