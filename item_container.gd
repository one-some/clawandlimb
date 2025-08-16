extends Node3D

const item_scene = preload("res://item_3d.tscn")

func _ready() -> void:
	Signals.drop_item.connect(_on_drop_item)
	
func _on_drop_item(item_instance: ItemInstance, pos: Vector3):
	if not item_instance: return
	
	var item = item_scene.instantiate()
	self.add_child(item)
	item.set_item(item_instance)
	item.global_position = pos
