extends Node3D

const tree_res = preload("res://tree.tscn")

func _ready() -> void:
	for _i in range(300):
		var tree = tree_res.instantiate()
		tree.position.x = randi_range(0, 100)
		tree.position.z = randi_range(0, 100)
		self.add_child(tree)
	%World.call_deferred("bake_level_navigation")
