extends Node3D

@onready var timer = $SpawnTimer
@onready var root = $".."
@onready var player = %Player

const Zombie = preload("res://zombie.tscn")
const Pig = preload("res://animal.tscn")

const MAX_ENEMIES = 12
const MAX_ANIMALS = 12

enum SpawnType {
	EVIL,
	NICE
}

func _on_spawn_timer_timeout() -> void:
	timer.wait_time = randf_range(5.0, 16.0)
	try_spawn(SpawnType.NICE if root.is_day else SpawnType.EVIL)

func get_guys(type: SpawnType) -> Array:
	return get_tree().get_nodes_in_group("Enemy" if type == SpawnType.EVIL else "Animal")

func get_guy_scene(type: SpawnType) -> PackedScene:
	return {
		SpawnType.EVIL: [Zombie],
		SpawnType.NICE: [Pig],
	}.get(type).pick_random()

func spawn_guy(scene: PackedScene, pos: Vector3) -> CharacterBody3D:
	var guy = scene.instantiate()
	if "target" in guy:
		guy.target = player
	self.add_child(guy)
	guy.global_position = pos
	return guy

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

func position_within_range_of_nodes_in_array(pos: Vector3, nodes: Array, node_range: float = 1.5) -> bool:
	for node in nodes:
		if node.global_position.distance_to(pos) <= node_range:
			return true
	return false

func try_spawn(type: SpawnType) -> void:
	if type == SpawnType.EVIL and root.is_day: return
	if type == SpawnType.NICE and not root.is_day: return
	
	var guys = get_guys(type)
	var guy_count = guys.size()
	
	var max_guys = MAX_ENEMIES if type == SpawnType.EVIL else MAX_ANIMALS
	if guy_count >= max_guys: return
	
	var horde_size = min(max_guys, guy_count + randi_range(1, 4)) - guy_count
	
	var guy_scene = get_guy_scene(type)
	
	var center = random_horde_origin_position()
	for i in range(horde_size):
		var pos = center
		# This is like....... O(n^999).... WOW!!!! THIS IS EVIL!!!!!!
		for tries in range(10):
			print("Attempted GUY spawn")
			if tries == 9:
				print("AHHHHHH!!!!F IX UR DAMN MATH!!!!!!! GODDDDDDD")

			if position_within_range_of_nodes_in_array(pos, guys):
				pos.x += randf() * 2.0
				pos.z += randf() * 2.0
				continue
			
			pos = NavigationServer3D.map_get_closest_point(
				get_world_3d().navigation_map,
				pos
			)
			
			pos.y += 3.0
			
			# Okayyyyyyy
			print("GUY spawned", pos)
			var guy = spawn_guy(guy_scene, pos)
			guys.append(guy)
			break
