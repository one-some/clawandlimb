class_name RecipeIngredient extends Resource

@export var item_data: ItemData
@export var count: int = 1

@warning_ignore("shadowed_variable")
func _init(item_data: ItemData, count: int) -> void:
	self.item_data = item_data
	self.count = count
