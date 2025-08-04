extends CharacterBody3D

@onready var cam = $"../Camera3D"
@onready var build = %Build
const ITEM_MAX_RANGE = 2.0

func attract_items() -> void:
	for item3d: Item3D in get_tree().get_nodes_in_group("Item"):
		var dist = item3d.global_position.distance_to(self.global_position)
		if dist > ITEM_MAX_RANGE: continue
		if dist < 1.0:
			if Inventory.add(item3d.item_instance):
				item3d.queue_free()
			continue
		
		var norm_dist = 1.0 - ((dist - 1.0) / ITEM_MAX_RANGE)
		var new_vel = item3d.global_position.direction_to(self.global_position) * 3.0 * norm_dist
		item3d.linear_velocity.x = new_vel.x
		item3d.linear_velocity.z = new_vel.z

func _physics_process(delta: float) -> void:
	attract_items()
	
	if State.active_ui: return
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
