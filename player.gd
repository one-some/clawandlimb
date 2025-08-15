extends CharacterBody3D

@onready var og_transform = self.global_transform
@onready var cam = $"../Camera3D"
const ITEM_MAX_RANGE = 2.0

var combat = CombatRecipient.new("Claire", 100.0)

func _ready() -> void:
	await get_tree().process_frame
	
	combat.died.connect(die)
	combat.took_damage.connect(func(_dmg): Signals.change_player_health.emit(combat))
	# Propagate stuff first
	combat.take_damage(CombatRecipient.DamageOrigin.GOD, 0.0)
	
	Signals.player_respawn_requested.connect(respawn)

func respawn() -> void:
	combat.reset()
	self.rotation_degrees.z = 0.0
	self.global_transform = self.og_transform

func die() -> void:
	Signals.player_died.emit()
	
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees:z", 90.0, 1.0)
	tween.play()

func _input(event: InputEvent) -> void:
	if event is not InputEventKey: return
	if State.build_mode: return
	if not Input.is_action_just_pressed("drop"): return
	
	var item = Inventory.inventory[Inventory.active_hotbar_index]
	if not item: return
	
	# I did this math off the top of my head without a reference and im so proud :D I love you JAMIE!!!
	# He's not related to this math I just am away on a trip and I miss him
	# Also if anybody's looking ya this is  was a piece of cake
	var angle = -(self.rotation.y - (PI / 2))
	var rot_angle = Vector3(cos(angle), 0.0, sin(angle))
	var target_pos = global_position + (rot_angle * 2.5)
	
	var drop_inst = item.duplicate()
	drop_inst.count = 1
	
	item.count -= drop_inst.count
	if item.count <= 0:
		Inventory.set_slot(Inventory.active_hotbar_index, null)
	else:
		Inventory.set_slot(Inventory.active_hotbar_index, item)
	
	Signals.drop_item.emit(drop_inst, target_pos)

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
	
	if self.global_position.y < -50.0:
		combat.die()
	
	if State.active_ui: return
	if State.build_mode: return
	
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
	self.velocity.y -= State.gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		self.velocity.y += 6.0
	
	if move_dir:
		self.rotation.y = lerp_angle(self.rotation.y, Vector2(move_dir.z, move_dir.x).angle(), 0.4)
	
	self.move_and_slide()
