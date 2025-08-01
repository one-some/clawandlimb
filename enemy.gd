extends CharacterBody3D

@export var nav_region: NavigationRegion3D
@export var target: Node3D

@onready var ray = $RayCast3D

var path_points = PackedVector3Array()
var nav_mesh = NavigationMesh.new()

func path_leads_to_target() -> bool:
	if not path_points:
		#print("[leadsto?] false - no pathpoints")
		return false
	
	var out = xy_distance_to(path_points[-1], target.global_position) < 0.1
	#print("[leadsto?] ", out)
	return out

func xy_distance_to(a: Vector3, b: Vector3) -> float:
	return sqrt(
		((b.x - a.x) ** 2) +
		((b.z - a.z) ** 2)
	)

func _ready() -> void:
	nav_mesh.sample_partition_type = NavigationMesh.SAMPLE_PARTITION_MONOTONE
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	
	var cell_height = 2.0
	NavigationServer3D.map_set_cell_height(
		nav_region.get_navigation_map(),
		cell_height
	)
	#nav_mesh.cell_size = 1.0
	nav_mesh.cell_height = cell_height
	nav_mesh.agent_height = 2.0
	nav_mesh.agent_radius = 0.5
	
	forge_path.call_deferred()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		self.velocity.y -= 14.0 * delta
	
	if path_points and self.global_position.distance_to(target.global_position) > 0.5:
		var dir = self.global_position.direction_to(path_points[0])
		self.velocity.x = dir.x * 5
		self.velocity.z = dir.z * 5
		
		if xy_distance_to(self.global_position, path_points[0]) < 0.1:
			path_points.remove_at(0)
	else:
		self.velocity.x = 0
		self.velocity.z = 0
	
	self.move_and_slide()

func forge_path() -> void:
	ray.target_position = target.global_position - self.global_position
	var collider = ray.get_collider()
	print(collider)
	if ray.get_collider() == target:
		#print("It's our lucky day!")
		path_points.clear()
		path_points.append(target.global_position)
		return
	
	var aabb = AABB(global_transform.origin - Vector3(0, global_transform.origin.y, 0), Vector3(10, 2, 10))
	aabb.position -= aabb.size / 2.0
	
	for i in range(3):
		var player_in_aabb = aabb.has_point(target.global_position)
		
		await bake_and_try_path(aabb)
		
		if path_leads_to_target() or player_in_aabb:
			#print("We are done")
			return
		
		#print("Not quite done..")
		
		aabb = aabb.grow(10.0)

	#print("SORRY I TRIED")

func rehash_existing_path() -> void:
	path_points = NavigationServer3D.map_get_path(
		nav_region.get_navigation_map(),
		self.global_position,
		target.global_position,
		true
	)

func bake_and_try_path(aabb: AABB) -> void:
	nav_mesh.clear()
	nav_mesh.filter_baking_aabb = aabb
	nav_region.navigation_mesh = nav_mesh
	nav_region.bake_navigation_mesh()
	await nav_region.bake_finished
	rehash_existing_path()
	#print("Done rebaking.")


func _on_path_redo_timeout() -> void:
	if nav_region.is_baking(): return
	
	if path_leads_to_target(): return
	rehash_existing_path()
	if path_leads_to_target(): return
	
	#print("\n---BEGIN---")
	forge_path()
	#print("\n\n")
