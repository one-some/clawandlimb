extends PanelContainer

@onready var name_label = $MarginContainer/VBoxContainer/Name
@onready var desc_label = $MarginContainer/VBoxContainer/Description

func _ready() -> void:
	self.visible = false
	Signals.tooltip_set_item.connect(set_item)
	Signals.tooltip_clear.connect(func(): self.visible = false)

func set_item(item_instance: ItemInstance) -> void:
	self.visible = true
	
	# TODO: SHriinnkk
	self.size.x = 0.0
	name_label.text = item_instance.item_data.item_name
	desc_label.text = item_instance.item_data.description

func _physics_process(delta: float) -> void:
	if not self.visible: return
	
	self.position = get_global_mouse_position() + Vector2(10, 0)
	var lower_bound = self.position.y + self.size.y
	var screen_size = get_viewport_rect().size - Vector2(8, 8)
	
	if lower_bound > screen_size.y:
		self.position.y -= lower_bound - screen_size.y
