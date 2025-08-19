extends Node3D

@onready var anim_player: AnimationPlayer = $WorldEnvironment/AnimationPlayer

const DAY_LENGTH_SECONDS = 60 * 1
var time_normalized = 0.9
var is_day = false

func set_day(p_is_day: bool) -> void:
	is_day = p_is_day
	Signals.change_daylight_landmark.emit(p_is_day)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey: return
	if not Input.is_action_just_pressed("debug"): return
	Inventory.add(ItemInstance.from_name("wooden_wall", 11))
	Inventory.add(ItemInstance.from_name("wooden_door", 2))
	Inventory.add(ItemInstance.from_name("workbench", 2))

func get_day_hour() -> float:
	return time_normalized * 24.0

func _ready() -> void:
	print(
		'"I must be going," he said out loud, and he added on a note of rather cheap wit, '
		+ '"and I\'m taking my box of cakes with me."'
	)
	get_tree().set_auto_accept_quit(false)
	$WorldEnvironment/AnimationPlayer.play("Cycle", -1, 0.5)

func _process(delta: float) -> void:
	time_normalized += delta / DAY_LENGTH_SECONDS
	
	if time_normalized >= 1.0:
		time_normalized = 0.0
	
	anim_player.seek(
		time_normalized * anim_player.get_animation("Cycle").length,
		true
	)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Save.save()
		print("Done saving!")
		get_tree().quit()
