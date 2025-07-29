extends GridMap

func generate_mesh_library() -> void:
	self.mesh_library = MeshLibrary.new()
	
	var path = "res://tex/tiles/"
	var dir = DirAccess.open(path)
	
	var i = 0
	for file in dir.get_files():
		if not file.ends_with(".png"): continue
		print(file)
		
		var mesh = PlaneMesh.new()
		mesh.material = StandardMaterial3D.new()
		mesh.material.albedo_texture = ResourceLoader.load(path + file)
		mesh.material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		
		var static_body = StaticBody3D.new()
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = BoxShape3D.new()
		static_body.add_child(collision_shape)
		
		self.mesh_library.create_item(i)
		self.mesh_library.set_item_mesh(i, mesh)
		self.mesh_library.set_item_shapes(i, [{
			"shape": collision_shape.shape,
			"transform": Transform3D.IDENTITY
		}])
		
		# ?
		static_body.queue_free()
		i += 1

func _ready() -> void:
	generate_mesh_library()
	for x in range(10):
		for z in range(10):
			self.set_cell_item(Vector3(x, 0, z), (x + z) % 2)
