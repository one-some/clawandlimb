extends Node

const item_db = preload("res://items/item_db.tres")

func get_item_data(name: String) -> ItemData:
	assert(name in item_db.items, "Item '%s' not in there" % name)
	return item_db.items.get(name)

func key_from_data(data: ItemData):
	return item_db.items.find_key(data)
