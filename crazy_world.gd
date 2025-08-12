extends Node3D

const Chunk = preload("res://worldren/chunk.tscn")

var ids = []

func _ready() -> void:
	var threads = []
	
	for x in range(-3, 3):
		for y in range(2, -2, -1):
			for z in range(-3, 3):
				var chunk = Chunk.instantiate()
				self.add_child(chunk)
				ids.append(WorkerThreadPool.add_task(chunk.generate.bind(Vector3(x, y, z))))
				#chunk.generate()

func _exit_tree() -> void:
	for id in ids:
		WorkerThreadPool.wait_for_task_completion(id)
