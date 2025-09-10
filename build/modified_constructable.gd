class_name ModifiedConstructable extends Resource

@export var constructable: PackedScene
@export var override_texture: Texture2D

func create() -> Constructable:
	var node: Constructable = constructable.instantiate()
	node.process_modifications(self)
	return node
