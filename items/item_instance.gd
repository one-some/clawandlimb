class_name ItemInstance

var item_data: ItemData
var count: int

@warning_ignore("shadowed_variable")
func _init(item_data: ItemData, count: int = 1) -> void:
	assert(item_data)
	assert(count)
	
	self.item_data = item_data
	self.count = count

func duplicate() -> ItemInstance:
	return ItemInstance.new(
		self.item_data,
		self.count
	)

func key() -> String:
	return ItemRegistry.key_from_data(item_data)

@warning_ignore("shadowed_variable")
static func from_name(name: String, count: int = 1) -> ItemInstance:
	var data = ItemRegistry.get_item_data(name)
	# Holy moly why can't I just call the constructor. Ok i get it but still
	var instance = load("res://items/item_instance.gd").new(data, count)
	return instance

func to_json():
	return {
		"name": ItemRegistry.key_from_data(item_data),
		"count": count
	}

static func from_json(data) -> ItemInstance:
	if data["count"] == 0: return null
	return ItemInstance.from_name(data["name"], data["count"])
