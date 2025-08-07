extends CharacterBody3D

@export var target: Node3D
@onready var agent = $NavigationAgent3D

func vec3_to_xz(vec: Vector3) -> Vector2:
	return Vector2(vec.x, vec.z)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		self.velocity.y -= 14.0 * delta
	
	agent.target_position = target.global_position
	
	var xz_vel = Vector2.ZERO
	var path_pos = agent.get_next_path_position()
	
	if not agent.is_navigation_finished():
		var next_pos = vec3_to_xz(path_pos)
		xz_vel = vec3_to_xz(self.global_position).direction_to(next_pos) * 4.0
	agent.velocity = Vector3(xz_vel.x, 0.0, xz_vel.y)
		
	self.move_and_slide()
	


func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	self.velocity.x = safe_velocity.x
	self.velocity.z = safe_velocity.z
