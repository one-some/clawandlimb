extends Node3D

@onready var interact_cast = $"../ShapeCast3D"
@onready var anim_player: AnimationPlayer = $"../AnimationPlayer"

var swinging = false

func _ready() -> void:
	anim_player.speed_scale = 2.0

func swing() -> void:
	if swinging: return
	swinging = true
	
	anim_player.play("AxeChop")
	await anim_player.animation_finished
	anim_player.play_backwards("AxeChop")
	await anim_player.animation_finished
	
	swinging = false

func _at_mid_swing():
	for i in range(interact_cast.get_collision_count()):
		var collider = interact_cast.get_collider(i)
		if "take_damage" not in collider: continue
		collider.take_damage(2)
		break

func _input(event: InputEvent) -> void:
	if State.active_ui: return
	if not Input.is_action_just_pressed("click"): return
	swing()
