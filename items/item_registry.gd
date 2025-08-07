extends Node

const item_db = preload("res://items/item_db.tres")

func get_item_data(key: String) -> ItemData:
	assert(key in item_db.items, "Item '%s' not in there" % key)
	return item_db.items.get(key)

func key_from_data(data: ItemData):
	return item_db.items.find_key(data)
