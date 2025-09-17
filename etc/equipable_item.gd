class_name EquippableItem extends Node3D

@export var item_id: String

enum ClickBehavior {
	CHOP,
	CUSTOM
}

@export var click_behavior = ClickBehavior.CHOP

func _on_use() -> void:
	pass

func _on_click() -> void:
	pass
