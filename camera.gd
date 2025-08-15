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
var last_hovered_interactable = null
var last_set_threed_cursor_pos = Vector3.ZERO

var right_click_down_pos = null

@export var interactable_material: Material

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

func cast_from_camera(collision_mask: int = 0xFFFFFFFF) -> Dictionary:
	var space_state = get_world_3d().direct_space_state

	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = self.project_ray_origin(mouse_pos)
	var ray_direction = self.project_ray_normal(mouse_pos)

	var ray_end = ray_origin + ray_direction * 1000
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = collision_mask
	
	return space_state.intersect_ray(query)

func try_move_threed_cursor() -> void:
	var result = cast_from_camera(1 << 4)
	#print(result["collider"].name if result else "No")
	if not result: return
	if result["collider"].name != "ChunkCollider": return
	
	var pos = result["position"]
	pos = pos.round()
	
	if pos == last_set_threed_cursor_pos:
		return
	last_set_threed_cursor_pos = pos
	
	if Input.is_action_pressed("build_y_lock"):
		pos.y = threed_cursor.global_position.y
	
	set_threed_cursor_pos(pos)

func set_threed_cursor_pos(pos: Vector3) -> void:
	threed_cursor.global_position = pos
	build_grid.global_position = pos + Vector3(0, 0.1, 0)
	((build_grid.mesh as PlaneMesh).material as ShaderMaterial).set_shader_parameter("pointer", Vector2(pos.x, pos.z))

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
	
	try_move_threed_cursor()

func visually_mark_interactable_recursive(interactable: Node3D, add: bool) -> void:
	if interactable is MeshInstance3D:
		interactable.material_overlay = interactable_material if add else null

	for child in interactable.get_children():
		visually_mark_interactable_recursive(child, add)

func do_interactable_stuff() -> void:
	# THIS IS ALL VERY UGLY BUT BEAR :teddy_bear: WITH ME!!!
	var cast_data = cast_from_camera()
	var interactable = (cast_data if cast_data else {}).get("collider")
	if interactable and "_interact" in interactable.get_parent():
		interactable = interactable.get_parent()
	
	if not interactable or "_interact" not in interactable:
		if last_hovered_interactable:
			visually_mark_interactable_recursive(last_hovered_interactable, false)
			last_hovered_interactable = null
		return

	if interactable != last_hovered_interactable:
		if last_hovered_interactable:
			visually_mark_interactable_recursive(last_hovered_interactable, false)
		visually_mark_interactable_recursive(interactable, true)
		last_hovered_interactable = interactable

func do_player_cam_process(delta: float) -> void:
	target_pole = target_pole.lerp(player.global_position, 0.4)
	
	do_interactable_stuff()

func set_camera_angle(angle_around: float, up_down: float) -> void:
	angle_around_point = angle_around
	angle_up_down = up_down
	
	# HACK: -0.01 to prevent total top view. That confuses the .look_at in
	# update_camera. Maybe gimbal lock or something....idk lol
	var almost_half_pi = (PI / 2) - 0.01
	angle_up_down = clampf(angle_up_down, -almost_half_pi, almost_half_pi)

func _on_right_click() -> void:
	if not last_hovered_interactable: return
	last_hovered_interactable._interact() 

func process_mouse_button_event_for_right_click(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_RIGHT: return
	
	
	var mouse_pos = DisplayServer.mouse_get_position()
	
	if event.pressed or not right_click_down_pos:
		right_click_down_pos = mouse_pos
		return
	
	var delta = mouse_pos.distance_to(right_click_down_pos)
	#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#Input.warp_mouse(right_click_down_pos)
	
	if delta < 25.0:
		_on_right_click()

func process_mouse_move(event: InputEventMouseMotion) -> void:
	if not Input.is_action_pressed("rotate"): return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var delta = mouse_pos.distance_to(right_click_down_pos)
	
	#if delta < 5.0: return
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	set_camera_angle(
		angle_around_point + event.relative.x / 200.0,
		angle_up_down + event.relative.y / 200.0
	)
	
	if delta < 25.0:
		_on_right_click()

func _input(event: InputEvent) -> void:
	if State.active_ui: return
	
	if event is InputEventKey and event.pressed:
		if Input.is_action_just_pressed("build_y_up"):
			set_threed_cursor_pos(threed_cursor.position + Vector3(0, 1, 0))
		elif Input.is_action_just_pressed("build_y_down"):
			set_threed_cursor_pos(threed_cursor.position + Vector3(0, -1, 0))
	
	if event is InputEventMouseMotion:
		process_mouse_move(event)

	elif event is InputEventMouseButton:
		distance_from_pole += {
			MOUSE_BUTTON_WHEEL_UP: -1,
			MOUSE_BUTTON_WHEEL_DOWN: 1,
		}.get(event.button_index, 0) * 0.5
		distance_from_pole = clampf(distance_from_pole, 2.0, 20.0)
		
		process_mouse_button_event_for_right_click(event)
	else:
		return
	update_camera()
