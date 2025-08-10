extends StaticBody3D

@onready var cast = $ShapeCast3D
@onready var csg = $CSGBox3D
@onready var og_transform = self.global_transform

const PIVOT = Vector3(0.5, 0, 0)
var open = false

var combat = CombatRecipient.new("Door", 10.0)
var start_pos = null
var end_pos = null

func _ready() -> void:
	combat.died.connect(func(): self.queue_free())

func set_start(pos: Vector3) -> void:
	self.global_position = pos

func set_end(pos: Vector3) -> void:
	self.global_position = pos

func finalize() -> void:
	for i in range(cast.get_collision_count()):
		var collider = cast.get_collider(i)
		if not collider: return
		print(collider)
		if collider is not CSGCombiner3D: return
		
		csg.material = collider.material
		csg.visible = true
		csg.reparent(collider)
		break


func _interact() -> void:
	open = not open
	
	og_transform = self.global_transform
	var tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_CIRC)
	tween.set_ease(Tween.EASE_IN)
	if open:
		tween.tween_method(rot_step, 0.0, 1.0, 0.4)
	else:
		tween.tween_method(rot_step, 1.0, 0.0, 0.4)
	tween.play()

func rot_step(t: float) -> void:
	var pivot = og_transform * PIVOT
	var current_angle: float = (PI / 2.0) * t
	var tween_rotation_quat = Quaternion(Vector3.UP, current_angle)

	var initial_radius_vector = og_transform.origin - pivot
	var rotated_radius_vector = tween_rotation_quat * initial_radius_vector
	var new_position = pivot + rotated_radius_vector
	var start_rotation_quat = og_transform.basis.get_rotation_quaternion()
	var new_rotation_quat = tween_rotation_quat * start_rotation_quat
	self.global_transform = Transform3D(Basis(new_rotation_quat), new_position)
