extends NavigationRegion3D

var baked_nav_mesh: NavigationMesh

func _ready() -> void:
	bake_level_navigation()

func bake_level_navigation() -> void:
	print("Starting navigation bake...")
	
	var source_geometry = NavigationMeshSourceGeometryData3D.new()
	for mesh_instance in find_children("", "MeshInstance3D"):
		source_geometry.add_mesh(mesh_instance.mesh, mesh_instance.transform)

	baked_nav_mesh = NavigationMesh.new()
	var callback = Callable(self, "_on_bake_finished")
	NavigationServer3D.bake_from_source_geometry_data_async(baked_nav_mesh, source_geometry, callback)

func _on_bake_finished() -> void:
	self.navigation_mesh = baked_nav_mesh
