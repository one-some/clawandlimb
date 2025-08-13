extends Node3D

@export var noise: Noise
@onready var where_are_we = $Navigation 
const CHUNK_SIZE = 16

var nav_regions: Dictionary[Vector2, NavigationRegion3D] = {}
var baking_queue = []

func update_chunk_collision(pos: Vector2) -> void:
	print("NOT UPDATING LOL", pos)
	return
