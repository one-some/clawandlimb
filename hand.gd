extends Node3D

@onready var interact_cast = $"../ShapeCast3D"
@onready var anim_player: AnimationPlayer = $"../AnimationPlayer"

enum SwingState {
	NONE,
	FORWARDS,
	BACKWARDS
}

var swing_state = SwingState.NONE
var equipped_model = null
var swing_hold = false

func _ready() -> void:
	anim_player.speed_scale = 2.0
	Signals.change_active_hotbar_slot.connect(change_equipped_model)

func change_equipped_model() -> void:
	var equipped = Inventory.inventory[Inventory.active_hotbar_index]
	equipped_model = null
	
	for item: EquippableItem in get_children():
		var real_deal = (not equipped and not item.item_id) or (equipped and item.item_id == ItemRegistry.key_from_data(equipped.item_data))
		item.visible = real_deal and equipped
		if real_deal: equipped_model = item

func swing() -> void:
	if swing_state: return
	if not equipped_model: return
	
	var animation = {
		$WoodenAxe: "AxeChop",
	}.get(equipped_model, "Punch")
	
	if animation == "Punch":
		$Fist.visible = true
	
	swing_state = SwingState.FORWARDS
	anim_player.play(animation)
	await anim_player.animation_finished
	
	if animation == "AxeChop":
		# HACK!!!
		swing_state = SwingState.BACKWARDS
		anim_player.play_backwards(animation)
		await anim_player.animation_finished
	
	swing_state = SwingState.NONE
	
	if animation == "Punch":
		$Fist.visible = false
	
	if swing_hold:
		# If we're still holding mouse1 or whatever, try to swing again
		swing()

func _at_mid_swing():
	if swing_state != SwingState.FORWARDS: return
	
	for i in range(interact_cast.get_collision_count()):
		var collider = interact_cast.get_collider(i)
		
		if "combat" in collider.get_parent():
			collider = collider.get_parent()
		if "combat" not in collider: continue
		
		var damage = {
			$WoodenAxe: 4.0,
		}.get(equipped_model, 2.0)
		
		collider.combat.take_damage(CombatRecipient.DamageOrigin.PLAYER, damage)
		break

func _input(event: InputEvent) -> void:
	if State.active_ui: return
	if State.build_mode: return
	
	if event is not InputEventMouseButton: return
	if event.button_index != MOUSE_BUTTON_LEFT: return
	
	swing_hold = event.pressed
	if not event.pressed: return
	
	swing()
