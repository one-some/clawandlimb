class_name ItemRecipe extends Resource

@export var ingredients: Dictionary[String, int]
@export var output_count: int = 1

func get_legit_ingredients_because_the_inspector_sucks_my_gock() -> Array[RecipeIngredient]:
	var out: Array[RecipeIngredient] = []
	
	for ingredient_key in ingredients.keys():
		var count = ingredients[ingredient_key]
		var ing_data = ItemRegistry.get_item_data(ingredient_key)
		out.append(RecipeIngredient.new(ing_data, count))

	return out
