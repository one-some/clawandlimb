extends Node3D

const tree_res = preload("res://tree.tscn")

@onready var nav: NavigationRegion3D = $"../CrazyWorld/NavigationRegion3D"

func _ready() -> void:
	return
	#for _i in range(300):
		#var tree = tree_res.instantiate()
		#tree.position =  NavigationServer3D.map_get_random_point(nav.get_navigation_map(), 0, false)
		#self.add_child(tree)
