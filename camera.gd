extends Camera3D

var focus_point = Vector2.ZERO
var angle_around_point = 0.0
var distance_from_focus = 10.0

func _input(event: InputEvent) -> void:
	if event is not InputEventMouseMotion: return
	if not event.is_action_pressed("rotate"): return
	angle_around_point += 0.07
	
	self.position.x = focus_point.x + cos(angle_around_point)
	self.position.z = focus_point.z + sin(angle_around_point)

func get_mouse_at_y(y: float) -> Variant:
	var mouse_pos = get_viewport().get_mouse_position()
	
	var ray_origin: Vector3 = self.project_ray_origin(mouse_pos)
	var ray_direction: Vector3 = self.project_ray_normal(mouse_pos)

	var plane = Plane(Vector3.UP, y)
	var intersection_point: Variant = plane.intersects_ray(ray_origin, ray_direction)

	return intersection_point
