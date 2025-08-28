extends EquippableItem

@onready var cam = %Camera3D
@export var break_material = StandardMaterial3D.new()
const VISUAL_OFFSET = Vector3(0.5, 0.5, 0.5)
var mesh = MeshInstance3D.new()
var cast = null

func _ready() -> void:
	mesh.mesh = BoxMesh.new()
	mesh.material_override = break_material
	mesh.top_level = true
	self.add_child(mesh)

func _process(delta: float) -> void:
	if not self.visible: return
	cast = cam.cast_from_camera(1 << 4)
	if not cast: return
	
	var pos: Vector3 = cast["position"]
	pos = pos.floor() + VISUAL_OFFSET
	#pos = (pos / ChunkData.CHUNK_SIZE).ceil() * ChunkData.CHUNK_SIZE
	mesh.position = pos

func _on_use() -> void:
	if not cast: return
	var chunk: VoxelMesh = cast["collider"].get_parent()
	var block_pos: Vector3 = mesh.position - VISUAL_OFFSET
	
	chunk.delete_area(AABB(
		block_pos.posmod(ChunkData.CHUNK_SIZE),
		Vector3(1, 1, 1) * 1
	), false)
	print(chunk)
