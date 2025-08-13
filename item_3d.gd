class_name Item3D extends RigidBody3D

@onready var sprite = $Sprite3D
var item_instance: ItemInstance

@warning_ignore("shadowed_variable")
func set_item(item_instance: ItemInstance) -> void:
	self.item_instance = item_instance
	sprite.texture = item_instance.item_data.texture
