extends Control

var voxel_scale = 0.5

var chunk_rects: Dictionary[Vector2, TextureRect] = {}

func create_image(chunk_pos: Vector2) -> Image:
	var img = Image.create_empty(
		ChunkManager.CHUNK_SIZE,
		ChunkManager.CHUNK_SIZE,
		true,
		Image.FORMAT_RGBA8
	)
	
	const SAMPLE_HEIGHT = ChunkManager.SEA_LEVEL + 0.5
	
	for x in range(ChunkManager.CHUNK_SIZE):
		for z in range(ChunkManager.CHUNK_SIZE):
			var global_pos = (chunk_pos * ChunkManager.CHUNK_SIZE) + Vector2(x, z)
			var sample_pos = Vector3(global_pos.x, SAMPLE_HEIGHT, global_pos.y)
			var density_at_d1 = VoxelMesh.sample_noise(sample_pos)
			
			var color = Color.MAGENTA
			if density_at_d1 < 0.0:
				color = Color.DARK_BLUE
			#elif abs(density_at_d1 - floor(density_at_d1)) < 0.1:
				# Experimental cartography heightmap whatever thingey... Could be cool if we get it working...
				#color = Color.WHITE
			else:
				var biome = VoxelMesh.get_biome(global_pos)
				
				match biome:
					VoxelMesh.BIOME_GRASS:
						color = Color.DARK_GREEN
					VoxelMesh.BIOME_TUNDRA:
						color = Color.LIGHT_BLUE
					VoxelMesh.BIOME_DESERT:
						color = Color.TAN
			
			if density_at_d1 >= 0.0:
				var gradient_x = VoxelMesh.sample_noise(sample_pos + Vector3(1, 0, 0)) - density_at_d1
				var gradient_z = VoxelMesh.sample_noise(sample_pos + Vector3(0, 0, 1)) - density_at_d1
				var terrain_slope_vector = Vector2(gradient_x, gradient_z)
				
				var dot_product = terrain_slope_vector.dot(Vector2(-1.0, -1.0).normalized())
				
				var light_adjust = dot_product * 0.7
				
				if light_adjust > 0:
					color = color.lightened(light_adjust)
				else:
					color = color.darkened(-light_adjust)
			
			img.set_pixel(x, z, color)
	
	img.generate_mipmaps()
	return img

func create_chunk_rect(chunk_pos: Vector2) -> void:
	var rect = TextureRect.new()
	chunk_rects[chunk_pos] = rect
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	rect.texture = ImageTexture.create_from_image(create_image(chunk_pos))
	rect.position = chunk_pos * ChunkManager.CHUNK_SIZE * voxel_scale
	rect.scale = Vector2(voxel_scale, voxel_scale)
	self.add_child(rect)

func zoom(delta: float) -> void:
	voxel_scale = clamp(voxel_scale * delta, 0.1, 10.0)
	
	for pos in chunk_rects:
		var rect = chunk_rects[pos]
		rect.position = pos * ChunkManager.CHUNK_SIZE * voxel_scale
		rect.scale = Vector2(voxel_scale, voxel_scale)

func _process(delta: float) -> void:
	var camera = get_viewport().get_camera_3d()
	var camera_ui_coords = Vector2(camera.global_position.x, camera.global_position.z)
	
	# God i am just not pleased with this. THIS MATH IS TOTALLY BOGUS!!!
	self.position = (self.size / 2) - (camera_ui_coords * voxel_scale)
	var offset = camera_ui_coords - (self.size / 2 / voxel_scale)
	var left_top_bound = (offset / ChunkManager.CHUNK_SIZE).floor()
	var right_bottom_bound = ((offset + (self.size / voxel_scale)) / ChunkManager.CHUNK_SIZE).ceil()
	
	for x in range(left_top_bound.x, right_bottom_bound.x):
		for z in range(left_top_bound.y, right_bottom_bound.y):
			var pos = Vector2(x, z)
			if pos in chunk_rects:
				continue
			create_chunk_rect(pos)
