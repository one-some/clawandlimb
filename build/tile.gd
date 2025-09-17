extends Constructable

@onready var box: CSGBox3D = $CSGBox3D
@export var material = StandardMaterial3D.new()

func _ready() -> void:
	self.allow_freehand = true
	box.material = material
	combat.name = "Tile"
	super()

func process_modifications(modified: ModifiedConstructable) -> void:
	material = material.duplicate()
	
	if modified.override_texture:
		material.albedo_texture = modified.override_texture

func set_end(pos: Vector3) -> void:
	if not start_pos:
		return
	self.visible = true
		
	end_pos = pos
	print(end_pos, "  ", start_pos)
	
	box.size = (end_pos - start_pos).abs() + Vector3(0.0, 0.2, 0.0)
	self.global_position = (end_pos + start_pos) / 2.0

func finalize() -> void:
	# TODO: Decal greedy meshing?
	pass
