extends Node3D

@onready var cam = %Camera3D
@onready var threed_cursor = $"%3DCursor"

var active_wall = null
var start_pos = null

func _input(event: InputEvent) -> void:
	if not cam.build_mode: return

	if not active_wall:
		active_wall = MeshInstance3D.new()
		active_wall.mesh = BoxMesh.new()
		self.add_child(active_wall)
		
	var new_pos = threed_cursor.position
	if Input.is_action_just_pressed("click"):
		if start_pos:
			active_wall = null
		start_pos = new_pos
		return
	
	if not start_pos or start_pos == new_pos:
		return
	
	active_wall.mesh.size = Vector3(0.3, 2.0, start_pos.distance_to(new_pos))
	active_wall.position = (new_pos + start_pos) / 2
	active_wall.look_at(new_pos)
