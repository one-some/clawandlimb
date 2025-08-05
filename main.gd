extends Node3D

@onready var sun = $DirectionalLight3D
var time_seconds = 12 * 60 * 60

func _input(event: InputEvent) -> void:
	if not Input.is_action_just_pressed("debug"): return
	Inventory.add(ItemInstance.from_name("wooden_axe"))

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)

func _process(delta: float) -> void:
	time_seconds += 2.0
	
	var hours = fmod(time_seconds / 60.0 / 60.0, 24.0)
	var sun_norm = fmod(hours + 8, 24.0) / 24.0
	sun.rotation.x = sun_norm * 2 * PI
	
	var bad_guys_work = hours > 20 and hours < 8
	for guy in get_tree().get_nodes_in_group("Enemy"):
		guy.process_mode = PROCESS_MODE_INHERIT if bad_guys_work else PROCESS_MODE_DISABLED
		guy.visible = bad_guys_work

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Save.save()
		print("Done saving!")
		get_tree().quit()
