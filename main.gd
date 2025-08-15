extends Node3D

@onready var sun = $DirectionalLight3D
var time_seconds = 12 * 60 * 60
var was_night = false

func _input(event: InputEvent) -> void:
	if not event is InputEventKey: return
	if not Input.is_action_just_pressed("debug"): return
	Inventory.add(ItemInstance.from_name("wooden_wall", 11))
	Inventory.add(ItemInstance.from_name("wooden_door", 2))
	Inventory.add(ItemInstance.from_name("workbench", 2))

func get_day_hour() -> float:
	return fmod(time_seconds / 60.0 / 60.0, 24.0)

func is_night() -> bool:
	var hours = get_day_hour()
	return hours <= 4.0 or hours >= 16.0

func _ready() -> void:
	print(
		'"I must be going," he said out loud, and he added on a note of rather cheap wit, '
		+ '"and I\'m taking my box of cakes with me."'
	)
	get_tree().set_auto_accept_quit(false)

func _process(delta: float) -> void:
	time_seconds += 4.0
	
	var hours = get_day_hour()
	var sun_norm = fmod(hours + 8, 24.0) / 24.0
	sun.rotation.x = sun_norm * 2 * PI
	
	var is_currently_night = is_night()
	if is_currently_night != was_night:
		Signals.change_daylight_landmark.emit(not is_currently_night)
		was_night = is_currently_night

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Save.save()
		print("Done saving!")
		get_tree().quit()
