extends Node

var items: Dictionary[String, ItemData] = {}

func _ready() -> void:
	const dir = "res://items/items"
	for file_name in DirAccess.get_files_at(dir):
		if not file_name.ends_with(".tres"): continue
		var data: ItemData = load(dir.path_join(file_name))
		var key = file_name.split(".")[0]
		items[key] = data
		
		if not data:
			print("HEY ITEM IS NULL. GIRL. THE ITEM. ", key)
			breakpoint
		
		print("loaded ", key, " - ", data)

func get_item_data(key: String) -> ItemData:
	assert(key in items, "Item '%s' not in there" % key)
	return items.get(key)

func key_from_data(data: ItemData):
	return items.find_key(data)
