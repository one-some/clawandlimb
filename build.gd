extends Node3D

@onready var cam = %Camera3D
@onready var threed_cursor = %"3DCursor"
@onready var world = $".."
@onready var build_grid = %BuildGrid

const plank = preload("res://tex/tiles/plank.png")
const WALL_HEIGHT = 3.0

var active_wall = null
var start_pos = null

func snapped_cursor_position() -> Vector3:
	var pos = threed_cursor.position

	if not start_pos:
		return pos
	
	var delta = start_pos - pos 
	if abs(delta.x) > abs(delta.z):
		pos.z = start_pos.z
	else:
		pos.x = start_pos.x
	return pos

func vec_floor_div(v: Vector2i, div: int) -> Vector2i:
	return Vector2i(
		floor(v.x / float(div)),
		floor(v.y / float(div))
	)

func set_build_mode(mode: bool):
	State.build_mode = mode
	threed_cursor.visible = mode
	build_grid.visible = mode
	
	if not mode and active_wall:
		active_wall["body"].queue_free()
		start_pos = null
		active_wall = null

func commit_wall() -> void:
	# Committing the wall
	var end_pos = snapped_cursor_position()
	var int_end_pos = vec_floor_div(Vector2i(
		end_pos.x,
		end_pos.y
	), world.CHUNK_SIZE)
	
	var int_start_pos = vec_floor_div(Vector2i(
		start_pos.x,
		start_pos.z
	), world.CHUNK_SIZE)
	print(int_start_pos, " - ", int_end_pos)
	
	for coord in Geometry2D.bresenham_line(
		int_start_pos,
		int_end_pos
	):
		print("Updating ", coord)
		await world.update_chunk_collision(coord)
	
	# Finish up materialization of wall
	active_wall["mesh"].mesh.material.albedo_color = Color.WHITE
	active_wall["mesh"].mesh.material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	active_wall = null
	
	# If u wanna continue girl.
	start_pos = end_pos

func setup_wall() -> void:
	active_wall = {
		"body": StaticBody3D.new(),
		"mesh": MeshInstance3D.new(),
		"shape": CollisionShape3D.new(),
	}
	
	active_wall["body"].add_to_group("NavigationObstacle")
	
	active_wall["body"].add_child(active_wall["mesh"])
	active_wall["body"].add_child(active_wall["shape"])
	active_wall["mesh"].mesh = BoxMesh.new()
	active_wall["shape"].shape = BoxShape3D.new()
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(Color.WHITE, 0.5)
	mat.albedo_texture = plank
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.texture_repeat = true
	active_wall["mesh"].mesh.material = mat
	
	self.add_child(active_wall["body"])

func update_building() -> void:
	if not State.build_mode: return
	
	if not active_wall:
		setup_wall()
		
	var new_pos = snapped_cursor_position()
	
	if not start_pos or start_pos == new_pos:
		return
	
	var mesh = active_wall["mesh"]
	mesh.mesh.size = Vector3(0.3, WALL_HEIGHT, start_pos.distance_to(new_pos))
	mesh.mesh.material.uv1_scale = Vector3(mesh.mesh.size.z, mesh.mesh.size.y, 1) * 3.0
	
	active_wall["shape"].shape.size = mesh.mesh.size
	active_wall["body"].position = (new_pos + start_pos) / 2
	if not active_wall["body"].global_position.is_equal_approx(new_pos):
		active_wall["body"].look_at(new_pos)
	
	active_wall["body"].position.y = WALL_HEIGHT / 2.0

func _process(delta: float) -> void:
	update_building()

func on_click() -> void:
	if start_pos:
		commit_wall()
		return
		
	start_pos = threed_cursor.position

func _input(event: InputEvent) -> void:
	if State.active_ui: return
	
	if event is InputEventKey:
		if Input.is_action_just_pressed("toggle_build"):
			set_build_mode(not State.build_mode)
		elif State.build_mode and Input.is_action_just_pressed("cancel"):
			set_build_mode(false)
	elif event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT: return
		if not event.pressed: return
		on_click()
