@tool
class_name ItemData extends Resource

@export var item_name: String = "New Item"
@export_multiline var description: String = ""
@export var texture: Texture2D
@export var max_stack: int = 64
@export var recipes: Array[ItemRecipe] = []
@export var item_constructable: PackedScene = null

func equals(other: ItemData) -> bool:
	# Wish this was an operator override!
	return item_name == other.item_name
