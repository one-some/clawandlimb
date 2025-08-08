extends Node3D

@onready var interact_cast = $"../ShapeCast3D"
@onready var anim_player: AnimationPlayer = $"../AnimationPlayer"

var equipped_model = null
var swinging = false

func _ready() -> void:
	anim_player.speed_scale = 2.0
	
	Signals.change_active_hotbar_slot.connect(change_equipped_model)

func change_equipped_model() -> void:
	var equipped = Inventory.inventory[Inventory.active_hotbar_index]
	equipped_model = null
	
	for item: EquippableItem in get_children():
		var real_deal = equipped and item.item_id == ItemRegistry.key_from_data(equipped.item_data)
		item.visible = real_deal
		if real_deal: equipped_model = item

func swing() -> void:
	if swinging: return
	if not equipped_model: return
	swinging = true
	
	anim_player.play("AxeChop")
	await anim_player.animation_finished
	anim_player.play_backwards("AxeChop")
	await anim_player.animation_finished
	
	swinging = false

func _at_mid_swing():
	for i in range(interact_cast.get_collision_count()):
		var collider = interact_cast.get_collider(i)
		if "combat" not in collider: continue
		collider.combat.take_damage(2)
		break

func _input(event: InputEvent) -> void:
	if State.active_ui: return
	
	if event is not InputEventMouseButton: return
	if not event.pressed: return
	if event.button_index != MOUSE_BUTTON_LEFT: return
	swing()
