extends HBoxContainer

const CraftingEntry = preload("res://crafting_entry.tscn")
const IngredientLabelSettings = preload("res://generic_labelsettings_20px.tres")
@onready var crafting_entry_container = $ItemTabs/ItemsCont/Items
@onready var details_texture_rect = $Details/VBoxContainer/Result/TextureRect
@onready var details_label = $Details/VBoxContainer/Result/Label
@onready var details_description = $Details/VBoxContainer/Description
@onready var ingredients_container = $Details/VBoxContainer/VBoxContainer/Ingredients
@onready var ingredients_label = $Details/VBoxContainer/VBoxContainer/IngLabel
@onready var craft_button = $Details/VBoxContainer/VBoxContainer/CraftButton

var recipes: Dictionary[ItemData, Array] = {}
var shown_recipe: ItemRecipe = null
var shown_recipe_result: ItemData = null

func _ready() -> void:
	for item: ItemData in ItemRegistry.item_db.items.values():
		recipes[item] = item.recipes
	
	update_shown_recipes()

func update_shown_recipes() -> void:
	for child in crafting_entry_container.get_children():
		child.queue_free()
	
	var first_recipe = true
	
	for item_data: ItemData in recipes.keys():
		for recipe in recipes[item_data]:
			# TODO: Check if in right category
			var entry = CraftingEntry.instantiate()
			entry.get_node("Panel/TextureRect").texture = item_data.texture
			entry.get_node("Panel/Label").text = item_data.item_name
			crafting_entry_container.add_child(entry)
			
			entry.pressed.connect(show_recipe.bind(item_data, recipe))
			
			if first_recipe:
				entry.pressed.emit()
				first_recipe = false

func show_recipe(item_data: ItemData, recipe: ItemRecipe) -> void:
	shown_recipe_result = item_data
	shown_recipe = recipe
	
	details_texture_rect.texture = item_data.texture
	details_label.text = item_data.item_name
	details_description.text = item_data.description
	ingredients_label.text = "Ingredients for x%s:" % recipe.output_count
	
	for child in ingredients_container.get_children():
		child.queue_free()
	
	craft_button.disabled = not Inventory.can_fufill_recipe(recipe)
	
	for ingredient in recipe.get_legit_ingredients_because_the_inspector_sucks_my_gock():
		var label = Label.new()
		label.text = "(x%s) %s" % [ingredient.count, ingredient.item_data.item_name]
		
		if Inventory.count_item(ingredient.item_data) >= ingredient.count:
			label.label_settings = IngredientLabelSettings
		else:
			label.label_settings = IngredientLabelSettings.duplicate()
			label.label_settings.font_color = Color.DARK_RED
		
		ingredients_container.add_child(label)


func _on_craft_button_pressed() -> void:
	if not shown_recipe: return
	assert(shown_recipe_result)
	if not Inventory.try_craft_recipe(shown_recipe): return
	
	Inventory.add(ItemInstance.new(shown_recipe_result, shown_recipe.output_count))
	print("YAY")
