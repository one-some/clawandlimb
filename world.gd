extends NavigationRegion3D

@onready var grid_map: GridMap = $GridMap
var baked_nav_mesh: NavigationMesh

func _ready() -> void:
	bake_level_navigation()

func bake_level_navigation() -> void:
	print("Starting nav bake...")
	
	var source_geometry = NavigationMeshSourceGeometryData3D.new()
	for mesh_instance in find_children("", "MeshInstance3D"):
		source_geometry.add_mesh(mesh_instance.mesh, mesh_instance.transform)

	var mesh_lib = grid_map.mesh_library
	assert(mesh_lib)
	
	for cell_pos in grid_map.get_used_cells():
		var id = grid_map.get_cell_item(cell_pos)
		if id == -1: continue
		
		var mesh = mesh_lib.get_item_mesh(id)
		if not mesh: continue
		
		var xform = Transform3D(
			grid_map.get_cell_item_basis(cell_pos),
			grid_map.map_to_local(cell_pos)
		)
		source_geometry.add_mesh(mesh, xform)

	baked_nav_mesh = NavigationMesh.new()
	var callback = Callable(self, "_on_bake_finished")
	NavigationServer3D.bake_from_source_geometry_data_async(baked_nav_mesh, source_geometry, callback)

func _on_bake_finished() -> void:
	print("OK DONE")
	self.navigation_mesh = baked_nav_mesh
