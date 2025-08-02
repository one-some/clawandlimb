extends Node

const item_db = preload("res://items/item_db.tres")

func get_item_data(name: String) -> ItemData:
	return item_db.items.get(name)
