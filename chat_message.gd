extends Control

@onready var label: Label = $Label

func set_message(text: String) -> void:
	label.text = text
	
	self.custom_minimum_size = label.size
