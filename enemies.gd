extends Node3D

@onready var timer = $SpawnTimer
@onready var root = $".."
@onready var player = %Player
const Zombie = preload("res://zombie.tscn")
const MAX_ENEMIES = 12

func _on_spawn_timer_timeout() -> void:
	print("yo")
	timer.wait_time = randf_range(5.0, 16.0)
	try_spawn()

func get_enemies() -> Array:
	return get_tree().get_nodes_in_group("Enemy")

func spawn_zombie(pos: Vector3) -> void:
	var zombie = Zombie.instantiate()
	zombie.nav_region = $"../World"
	zombie.target = player
	self.add_child(zombie)
	zombie.global_position = pos

func random_horde_origin_position() -> Vector3:
	# Awesome math idea i just had. Pls dont laugh.
	var theta = randf() * 2 * PI
	# Range of spawn from player center
	var r = randf_range(16.0, 32.0)
	
	var pos = player.global_position
	pos.y = 3.0
	pos.x += r * cos(theta)
	pos.z += r * sin(theta)
	return pos

func position_within_range_of_nodes_in_array(pos: Vector3, nodes: Array, range: float = 1.5) -> bool:
	for node in nodes:
		if node.global_position.distance_to(pos) <= range:
			return true
	return false

func try_spawn() -> void:
	if not root.is_night():
		print("Not night")
		return
	
	var enemies = get_enemies()
	var enemy_count = enemies.size()
	if enemy_count >= MAX_ENEMIES: return
	
	var horde_size = min(MAX_ENEMIES, enemy_count + randi_range(1, 4)) - enemy_count
	
	var center = random_horde_origin_position()
	for i in range(horde_size):
		var pos = center
		# This is like....... O(n^999).... WOW!!!! THIS IS EVIL!!!!!!
		for tries in range(10):
			if tries == 9:
				print("AHHHHHH!!!!F IX UR DAMN MATH!!!!!!! GODDDDDDD")

			if position_within_range_of_nodes_in_array(pos, enemies):
				pos.x += randf() * 2.0
				pos.z += randf() * 2.0
				continue
			
			# Okayyyyyyy
			spawn_zombie(pos)
			break
