extends Node3D

@onready var cam = %Camera3D
@onready var threed_cursor = $"%3DCursor"

const plank = preload("res://tex/tiles/plank.png")
const WALL_HEIGHT = 3.0

var build_mode = false
var active_wall = {}
var start_pos = null

func set_build_mode(mode: bool):
	build_mode = mode
	threed_cursor.visible = mode
	
	if not mode and active_wall:
		active_wall["body"].queue_free()
		active_wall = null

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_build"):
		set_build_mode(not build_mode)
		return
	
	if build_mode and Input.is_action_just_pressed("cancel"):
		set_build_mode(false)
		return

	if not build_mode: return

	if not active_wall:
		active_wall = {
			"body": StaticBody3D.new(),
			"mesh": MeshInstance3D.new(),
			"shape": CollisionShape3D.new(),
		}
		
		active_wall["body"].add_child(active_wall["mesh"])
		active_wall["body"].add_child(active_wall["shape"])
		active_wall["mesh"].mesh = BoxMesh.new()
		active_wall["shape"].shape = BoxShape3D.new()
		
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = plank
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.texture_repeat = true
		active_wall["mesh"].mesh.material = mat
		
		self.add_child(active_wall["body"])
		
	var new_pos = threed_cursor.position
	if Input.is_action_just_pressed("click"):
		if start_pos:
			%World.bake_level_navigation()
			active_wall = null
		start_pos = new_pos
		return
	
	if not start_pos or start_pos == new_pos:
		return
	
	var mesh = active_wall["mesh"]
	mesh.mesh.size = Vector3(0.3, WALL_HEIGHT, start_pos.distance_to(new_pos))
	mesh.mesh.material.uv1_scale = Vector3(mesh.mesh.size.z, mesh.mesh.size.y, 1) * 3.0
	
	active_wall["shape"].shape.size = mesh.mesh.size
	active_wall["body"].position = (new_pos + start_pos) / 2
	if active_wall["body"].global_position != new_pos:
		active_wall["body"].look_at(new_pos)
	active_wall["body"].position.y = WALL_HEIGHT / 2.0
