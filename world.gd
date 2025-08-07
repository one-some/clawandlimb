extends Node3D

@export var noise: Noise
@onready var where_are_we = $Navigation 
@onready var grid_map = $GridMap
const CHUNK_SIZE = 16

var nav_regions: Dictionary[Vector2, NavigationRegion3D] = {}
var baking_queue = []

func update_chunk_collision(pos: Vector2) -> void:
	print("Updating", pos)
	var region = nav_regions[pos]
	
	if region.is_baking():
		print("ALREADY BAKING LOSER!!!")
		return
	
	region.bake_navigation_mesh()
	await region.bake_finished

func create_chunk(pos: Vector2) -> void:
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			var local_pos = Vector2(x, y)
			var global_pos = (pos * CHUNK_SIZE) + local_pos
			
			var item = (noise.get_noise_2dv(global_pos) + 1.0) / 2.0
			grid_map.set_cell_item(Vector3(global_pos.x, 0, global_pos.y), round(item))
	
	await get_tree().process_frame
	
	# Nav stuff
	var chunk_global_pos = Vector3(pos.x * CHUNK_SIZE, 0.0, pos.y * CHUNK_SIZE)
	var nav_region = NavigationRegion3D.new()
	nav_regions[pos] = nav_region
	where_are_we.add_child(nav_region)
	
	var nav_mesh = NavigationMesh.new()
	nav_region.navigation_mesh = nav_mesh
	
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	# TODO: Change source mode for performance...?
	
	var aabb_size = Vector3(CHUNK_SIZE, 5.0, CHUNK_SIZE)
	var aabb_pos = chunk_global_pos - Vector3(0, aabb_size.y / 2.0, 0)
	var baking_aabb = AABB(aabb_pos, aabb_size)
	baking_aabb = baking_aabb.grow(1.0)
	nav_mesh.filter_baking_aabb = baking_aabb
	
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nav_mesh.geometry_source_group_name = "NavigationObstacle"
	nav_mesh.border_size = 1.0
	
	nav_region.bake_navigation_mesh()
	await nav_region.bake_finished

func _ready() -> void:
	for x in range(-2, 2):
		for y in range(-2, 2):
			create_chunk(Vector2(x, y))
