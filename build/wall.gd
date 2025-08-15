extends Constructable

const Plank = preload("res://tex/tiles/7_plank.png")
const WALL_HEIGHT = 3.0

@onready var box = $Wall/CSGBox3D

var material = StandardMaterial3D.new()

func _ready() -> void:
	self.visible = false
	combat.name = "Wall"
	
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(Color.WHITE, 0.5)
	material.albedo_texture = Plank
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.texture_repeat = true
	box.material = material

func set_start(pos: Vector3) -> void:
	start_pos = pos
	update_points()

func set_end(pos: Vector3) -> void:
	end_pos = pos
	update_points()

func update_points() -> void:
	self.visible = false
	if start_pos == null or end_pos == null: return
	if start_pos == end_pos: return
	self.visible = true
	
	box.size = Vector3(0.3, WALL_HEIGHT, start_pos.distance_to(end_pos))
	material.uv1_scale = Vector3(box.size.z, box.size.y, 1) * 3.0
	#material.uv1_scale = Vector3(box.size.x, 1, 1) * 3.0
	
	#collision_shape.shape.size = mesh.size
	self.position = (end_pos + start_pos) / 2.0
	if not self.global_position.is_equal_approx(end_pos):
		self.look_at(end_pos)
	
	self.position.y = (WALL_HEIGHT / 2.0)

func finalize() -> void:
	material.albedo_color = Color.WHITE
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED

func _interact() -> void:
	print("Hello my name is construct")
