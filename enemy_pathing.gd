extends NavigationAgent3D

@onready var body: CharacterBody3D = self.get_parent()

func _ready() -> void:
	$PathTimer.timeout.connect(repath)
	$PathTimer.wait_time = randf_range(0.5, 1.5)

func vec3_to_xz(vec: Vector3) -> Vector2:
	return Vector2(vec.x, vec.z)

func repath() -> void:
	# HEAVY!!!!!
	self.target_position = body.target.global_position

func _physics_process(delta: float) -> void:
	var xz_vel = Vector2.ZERO
	var path_pos = self.get_next_path_position()
	
	if self.is_navigation_finished():
		if body.global_position.distance_to(body.target.global_position) > self.target_desired_distance:
			# Watch out for this okaieeee?
			repath()
	else:
		var next_pos = vec3_to_xz(path_pos)
		xz_vel = vec3_to_xz(body.global_position).direction_to(next_pos) * 4.0
		
	self.velocity = Vector3(xz_vel.x, 0.0, xz_vel.y)

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	body.velocity.x = safe_velocity.x
	body.velocity.z = safe_velocity.z
