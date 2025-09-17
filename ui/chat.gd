extends VBoxContainer

const ChatMessageControl = preload("res://ui/chat_message.tscn")

@onready var line_edit: LineEdit = $LineEdit

func create_message(text: String, color: Color) -> void:
	var message_control = ChatMessageControl.instantiate()
	message_control.modulate = color
	self.add_child(message_control)
	self.move_child(message_control, 1)
	message_control.set_message(text)

func _ready() -> void:
	Signals.make_chat_message.connect(create_message)

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
	create_message("[%s]: %s" % [State.player_name, new_text], Color.WHITE)
	line_edit.clear()

func _on_line_edit_focus_exited() -> void:
	print("EXITING FOCUS")
	line_edit.visible = false
	line_edit.clear()
	State.set_active_ui(State.ActiveUI.NONE)
