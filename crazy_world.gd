extends Node3D

const Chunk = preload("res://worldren/chunk.tscn")

func _ready() -> void:
	for x in range(-3, 3):
		for y in range(-2, 2):
			for z in range(-3, 3):
				var chunk = Chunk.instantiate()
				self.add_child(chunk)
				chunk.chunk_pos = Vector3(x, y, z)
				chunk.generate()
