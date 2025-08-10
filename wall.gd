extends StaticBody3D

const Plank = preload("res://tex/tiles/plank.png")
const WALL_HEIGHT = 3.0

var mesh_instance: MeshInstance3D
var mesh: BoxMesh
var collision_shape: CollisionShape3D

var material = StandardMaterial3D.new()
var combat = CombatRecipient.new("Wall", 10.0)

var start_pos = null
var end_pos = null

func _ready() -> void:
	# FIXME: Do we need to bind here
	combat.died.connect(func(): self.queue_free())
	
	# Honestly just make it in code because every resource needs to be unique
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = BoxMesh.new()
	mesh = mesh_instance.mesh
	self.add_child(mesh_instance)
	
	collision_shape = CollisionShape3D.new()
	collision_shape.shape = BoxShape3D.new()
	self.add_child(collision_shape)
	
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(Color.WHITE, 0.5)
	material.albedo_texture = Plank
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.texture_repeat = true
	mesh.material = material

func set_start(pos: Vector3) -> void:
	start_pos = pos
	update_points()

func set_end(pos: Vector3) -> void:
	end_pos = pos
	update_points()

func update_points() -> void:
	if start_pos == null or end_pos == null: return
	if start_pos == end_pos: return
	
	mesh.size = Vector3(0.3, WALL_HEIGHT, start_pos.distance_to(end_pos))
	material.uv1_scale = Vector3(mesh.size.z, mesh.size.y, 1) * 3.0
	
	collision_shape.shape.size = mesh.size
	self.position = (end_pos + start_pos) / 2.0
	if not self.global_position.is_equal_approx(end_pos):
		self.look_at(end_pos)
	
	self.position.y = (WALL_HEIGHT / 2.0)

func finalize() -> void:
	material.albedo_color = Color.WHITE
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED

func _interact() -> void:
	print("Hello my name is construct")
