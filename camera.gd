extends Camera3D

@onready var player = $"../Player"
@onready var threed_cursor = %"3DCursor"
@onready var build_grid = %BuildGrid
@onready var spring_cast = $SpringCast

var target_pole = Vector3(0.0, 2.0, 0.0)
var angle_around_point = 0.0
var distance_from_pole = 5.0
var angle_up_down = PI / 4.0
var camera_shake_strength = 0.0

func _ready() -> void:
	update_camera()
	Signals.camera_shake.connect(_on_camera_shake)

func _on_camera_shake(strength: float, origin: Vector3) -> void:
	camera_shake_strength = strength / max(1.0, 2.0 * log(player.global_position.distance_to(origin) + 1))

func update_camera() -> void:
	var height = distance_from_pole * sin(angle_up_down)
	var personal_space = distance_from_pole * cos(angle_up_down)
	
	var dream_pos = Vector3(
		target_pole.x + (personal_space * cos(angle_around_point)),
		height,
		target_pole.z + (personal_space * sin(angle_around_point))
	)
	
	spring_cast.position = target_pole
	spring_cast.target_position = dream_pos - spring_cast.position
	
	if not State.build_mode and spring_cast.is_colliding():
		self.position = spring_cast.get_collision_point()
	else:
		self.position = dream_pos
	
	self.look_at(target_pole)

func _physics_process(delta: float) -> void:
	if State.active_ui: return
	
	if State.build_mode:
		do_freecam_process(delta)
	else:
		do_player_cam_process(delta)
	
	# Shoutout JAMIE <3
	var cam_key_input_dir = Input.get_vector("camera_left", "camera_right", "camera_down", "camera_up")
	if cam_key_input_dir:
		print(cam_key_input_dir)
		set_camera_angle(
			angle_around_point + (cam_key_input_dir.x / 25.0),
			angle_up_down + (cam_key_input_dir.y / 40.0)
		)
	
	#camera_shake_strength = max(0.0, camera_shake_strength - 0.1)
	camera_shake_strength = lerpf(camera_shake_strength, 0, 0.1)
	
	if camera_shake_strength:
		self.h_offset += randf() * camera_shake_strength * (1 if self.h_offset < 0 else -1)
		self.v_offset += randf() * camera_shake_strength * (1 if self.v_offset < 0 else -1)
	else:
		self.h_offset = 0.0
		self.v_offset = 0.0
	
	update_camera()

func do_freecam_process(delta: float):
	var input_dir = Input.get_vector("move_left", "move_right", "move_backwards", "move_forwards")
	if input_dir:
		var forward = -self.global_transform.basis.z
		var right = self.global_transform.basis.x
		
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right.normalized()
		
		var speed_multiplier = 3.0 if Input.is_action_pressed("faster") else 1.0
		var move_dir = (forward * input_dir.y) + (right * input_dir.x)
		target_pole += move_dir * delta * distance_from_pole * speed_multiplier
	
	var space_state = get_world_3d().direct_space_state

	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = self.project_ray_origin(mouse_pos)
	var ray_direction = self.project_ray_normal(mouse_pos)

	var ray_end = ray_origin + ray_direction * 1000
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 1 << 4

	var result = space_state.intersect_ray(query)
	if result and result["collider"].name == "GridMap":
		var pos = result["position"]
		pos.x = round(pos.x)
		pos.z = round(pos.z)
		threed_cursor.global_position = pos
		build_grid.global_position = pos + Vector3(0, 0.1, 0)
		((build_grid.mesh as PlaneMesh).material as ShaderMaterial).set_shader_parameter("pointer", Vector2(pos.x, pos.z))

func do_player_cam_process(delta: float):
	target_pole = target_pole.lerp(player.global_position, 0.4)

func set_camera_angle(angle_around: float, up_down: float) -> void:
	angle_around_point = angle_around
	angle_up_down = up_down
	
	# HACK: -0.01 to prevent total top view. That confuses the .look_at in
	# update_camera. Maybe gimbal lock or something....idk lol
	angle_up_down = clampf(angle_up_down, 0.3, (PI / 2) - 0.01)

func _input(event: InputEvent) -> void:
	if State.active_ui: return
	
	if event is InputEventMouseMotion:
		if not Input.is_action_pressed("rotate"): return
		set_camera_angle(
			angle_around_point + event.relative.x / 200.0,
			angle_up_down + event.relative.y / 200.0
		)

	elif event is InputEventMouseButton:
		distance_from_pole += {
			MOUSE_BUTTON_WHEEL_UP: -1,
			MOUSE_BUTTON_WHEEL_DOWN: 1,
		}.get(event.button_index, 0) * 0.5
		distance_from_pole = clampf(distance_from_pole, 2.0, 20.0)
	else:
		return
	update_camera()

func get_mouse_at_y(y: float) -> Variant:
	var mouse_pos = get_viewport().get_mouse_position()
	
	var ray_origin: Vector3 = self.project_ray_origin(mouse_pos)
	var ray_direction: Vector3 = self.project_ray_normal(mouse_pos)

	var plane = Plane(Vector3.UP, y)
	var intersection_point: Variant = plane.intersects_ray(ray_origin, ray_direction)

	return intersection_point
