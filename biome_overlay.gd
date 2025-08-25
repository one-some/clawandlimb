extends TextureRect

@onready var player = get_tree().get_first_node_in_group("Player")

var current_biome = null

const BIOME_COLORS = {
	VoxelMesh.BIOME_TUNDRA: Color("64b4fe55"),
	VoxelMesh.BIOME_DESERT: Color("fea56455"),
}

func _ready() -> void:
	self.visible = true
	self.modulate = Color.TRANSPARENT

func _on_check_biome_timeout() -> void:
	# Yeah its ugly whatever
	var biome = (ChunkManager.chunks.values()[0] as VoxelMesh).get_biome(Vector2(
		player.global_position.x,
		player.global_position.z,
	))
	
	if biome == current_biome: return
	current_biome = biome
	
	var tween = create_tween()
	tween.tween_property(
		self,
		"modulate",
		BIOME_COLORS.get(biome, Color.TRANSPARENT),
		2.0
	)
	tween.play()
