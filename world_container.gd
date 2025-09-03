extends VBoxContainer

signal delete_decision(do_delete: bool)
const WorldEntry = preload("res://world_ui_entry.tscn")
@onready var confirmation_dialog: Panel = %ConfirmationDialog
@onready var confirmation_world_name: Label = %ConfirmationWorldName

func _ready() -> void:
	for save: WorldSave in Save.get_saves():
		var panel = WorldEntry.instantiate()
		self.add_child(panel)
		panel.setup(save)
		
		panel.delete_pressed.connect(func():
			if not save.can_delete_save_CHANGECARE():
				OS.alert("This save cannot be deleted!", "Watch out!")
				return
			
			confirmation_world_name.text = save.get_name()
			
			confirmation_dialog.visible = true
			var decision = await delete_decision
			confirmation_dialog.visible = false
			
			if not decision: return
			save.delete()
			panel.queue_free()
		)

func _on_delete_pressed() -> void:
	delete_decision.emit(true)

func _on_back_pressed() -> void:
	delete_decision.emit(false)
