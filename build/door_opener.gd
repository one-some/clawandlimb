extends StaticBody3D

const PIVOT = Vector3(0.5, 0, 0)
var open = false
var opening = false
var og_transform = null

func _interact() -> void:
	if opening: return
	opening = true
	
	open = not open
	
	if not og_transform:
		og_transform = self.global_transform
	
	var tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	if open:
		tween.tween_method(rot_step, 0.0, 1.0, 0.4)
	else:
		tween.tween_method(rot_step, 1.0, 0.0, 0.4)
	tween.play()
	
	await tween.finished
	opening = false

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
