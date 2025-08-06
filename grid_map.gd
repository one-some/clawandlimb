extends GridMap

@export var noise: Noise

func to_grayscale(image: Image) -> void:
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var color = image.get_pixel(x, y)
			var lum = color.r * 0.299 + color.g * 0.587 + color.b * 0.114
			image.set_pixel(x, y, Color(lum, lum, lum, color.a))

func generate_mesh_library() -> void:
	self.mesh_library = MeshLibrary.new()
	
	var path = "res://tex/tiles/"
	var dir = DirAccess.open(path)
	
	var i = 0
	for file in dir.get_files():
		if not file.ends_with(".png"): continue
		
		var mesh = PlaneMesh.new()
		mesh.size = Vector2(1, 1)
		mesh.material = StandardMaterial3D.new()
		mesh.material.albedo_texture = ResourceLoader.load(path + file)
		mesh.material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		
		var image = mesh.material.albedo_texture.get_image()
		if not image.is_compressed():
			to_grayscale(image)
			image.bump_map_to_normal_map(4.0)
			mesh.material.normal_enabled = true
			mesh.material.normal_texture = ImageTexture.create_from_image(image)
		
		self.mesh_library.create_item(i)
		self.mesh_library.set_item_mesh(i, mesh)
		
		# Really shouldnt be making so many of these
		self.mesh_library.set_item_shapes(i, [
			HeightMapShape3D.new(),
			Transform3D.IDENTITY,
		])
		
		i += 1

func _ready() -> void:
	generate_mesh_library()
	for x in range(-100, 100):
		for z in range(-100, 100):
			var item = (noise.get_noise_2d(x, z) + 1.0) / 2.0
			#item = 5.0
			self.set_cell_item(Vector3(x, 0, z), round(item))
