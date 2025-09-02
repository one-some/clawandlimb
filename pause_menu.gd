extends Control

const MainMenu = preload("res://main_menu.tscn")
@onready var save_notif = $SaveNotif

func _ready() -> void:
	set_pause_menu_open(false)
	Signals.ui_changed.connect(func(ui): set_pause_menu_open(ui == State.ActiveUI.PAUSE))

func save() -> void:
	save_notif.visible = true
	State.active_save.write()
	save_notif.visible = false

func _input(event: InputEvent) -> void:
	if not event is InputEventKey: return
	if not event.pressed: return
	if not event.is_action("esc"): return
	
	print("bleh", State.active_ui)
	
	if State.active_ui and State.active_ui != State.ActiveUI.PAUSE: return
	State.set_active_ui(State.ActiveUI.PAUSE if not State.active_ui else State.ActiveUI.NONE)

func set_pause_menu_open(open: bool) -> void:
	self.visible = open
	Signals.ui_blur.emit(open)
	if open:
		save()

func _on_dont_pressed() -> void:
	State.set_active_ui(State.ActiveUI.NONE)
	set_pause_menu_open(false)

func _on_blowup_pressed() -> void:
	OS.alert("KABOOM", "YOU ASKED FOR IT...!!!!!!")

func _on_quit_pressed() -> void:
	save()
	get_tree().change_scene_to_packed(MainMenu)
