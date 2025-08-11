class_name ChunkData extends Resource

const CHUNK_SIZE = 16

var material = PackedInt32Array()
var density = PackedFloat32Array()

func _init() -> void:
	material.resize(CHUNK_SIZE ** 3)
	material.fill(0)
	
	density.resize(CHUNK_SIZE ** 3)
	density.fill(0.0)

func get_index(pos: Vector3) -> int:
	var idx: int = pos.x + (pos.y * CHUNK_SIZE) + (pos.z * CHUNK_SIZE * CHUNK_SIZE)
	return idx
