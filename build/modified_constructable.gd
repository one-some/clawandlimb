class_name ModifiedConstructable extends Resource

@export var constructable: PackedScene
@export var override_texture: Texture2D

func create() -> Constructable:
	var node: Constructable = constructable.instantiate()
	assert(self.resource_path)
	assert("::" not in self.resource_path)
	node.register_path(self.resource_path)
	node.process_modifications(self)
	return node
