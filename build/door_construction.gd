extends Constructable

@onready var holder = $Door
@onready var cast = $Door/ShapeCast3D
@onready var csg = $Door/CSGBox3D

func _ready() -> void:
	one_and_done = true
	combat.name = "Door"

func set_end(pos: Vector3) -> void:
	self.global_position = pos
	
func finalize() -> void:
	for i in range(cast.get_collision_count()):
		var collider = cast.get_collider(i)
		if not collider: return
		if collider is not CSGCombiner3D: return
		var wall_node = collider.get_parent()
		
		csg.material = wall_node.material
		#csg.visible = false
		csg.reparent(collider)
		break
	
	if csg.get_parent() == holder:
		csg.queue_free()
