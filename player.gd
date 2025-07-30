extends CharacterBody3D

@onready var cam = $"../Camera3D"
@onready var build = %Build
@onready var interact_cast = $ShapeCast3D

func _physics_process(delta: float) -> void:
	if build.build_mode: return
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_backwards", "move_forwards")
	
	var forward = -cam.global_transform.basis.z
	var right = cam.global_transform.basis.x
	
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right.normalized()
	
	var move_dir = (forward * input_dir.y) + (right * input_dir.x)
	
	self.velocity.x = move_dir.x * 6.0
	self.velocity.z = move_dir.z * 6.0
	self.velocity.y -= 14.0 * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		self.velocity.y += 6.0
	
	if move_dir:
		self.rotation.y = lerp_angle(self.rotation.y, Vector2(move_dir.z, move_dir.x).angle(), 0.4)
	
	self.move_and_slide()

func _input(event: InputEvent) -> void:
	if not Input.is_action_just_pressed("click"): return
	
	for i in range(interact_cast.get_collision_count()):
		var collider = interact_cast.get_collider(i)
		if "take_damage" not in collider: continue
		collider.take_damage()
		break
