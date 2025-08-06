extends ScrollContainer

const crafting_entry = preload("res://crafting_entry.tscn")

func _ready():
	self.visible = false
	
	for i in range(10):
		$CraftingList.add_child(crafting_entry.instantiate())
