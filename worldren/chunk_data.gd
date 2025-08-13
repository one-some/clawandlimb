class_name ChunkData extends Resource

const CHUNK_SIZE = 16
const PADDED_SIZE = CHUNK_SIZE + 1

var material = PackedInt32Array()
var density = PackedFloat32Array()

func _init() -> void:
	material.resize(PADDED_SIZE ** 3)
	material.fill(0)
	
	density.resize(PADDED_SIZE ** 3)
	density.fill(0.0)

func get_index(pos: Vector3) -> int:
	@warning_ignore("narrowing_conversion")
	var idx: int = pos.x + (pos.y * PADDED_SIZE) + (pos.z * PADDED_SIZE * PADDED_SIZE)
	return idx
