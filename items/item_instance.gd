class_name ItemInstance

var item_data: ItemData
var count: int

func _init(item_data: ItemData, count: int = 1) -> void:
	assert(item_data)
	assert(count)
	
	self.item_data = item_data
	self.count = count
