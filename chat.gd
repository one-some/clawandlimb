extends VBoxContainer

const ChatMessageControl = preload("res://chat_message.tscn")

@onready var line_edit: LineEdit = $LineEdit

func _ready() -> void:
	for message in ["hellooo", "iiiiiiiiimmmmmmmmcllllllllllaiiiiiiiiireeee"]:
		var x = ChatMessageControl.instantiate()
		self.add_child(x)
		x.set_message(message)

func _input(event: InputEvent) -> void:
	if event is not InputEventKey: return
	if not event.is_pressed(): return
	if State.active_ui:
		if State.active_ui == State.ActiveUI.CHAT and event.is_action("esc"):
			line_edit.release_focus()
		return
	
	if not event.is_action("chat"): return
	
	line_edit.visible = true
	line_edit.grab_focus()
	State.set_active_ui(State.ActiveUI.CHAT)

func _on_line_edit_text_submitted(new_text: String) -> void:
	if not new_text.strip_edges(): return
	var message_control = ChatMessageControl.instantiate()
	self.add_child(message_control)
	message_control.set_message("[%s]: %s" % [State.player_name, new_text])
	line_edit.clear()


func _on_line_edit_focus_exited() -> void:
	print("EXITING FOCUS")
	self.visible = false
	State.set_active_ui(State.ActiveUI.NONE)
