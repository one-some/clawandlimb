extends Node3D

@onready var fist = $Fist
@onready var interact_cast = $"../ShapeCast3D"
@onready var anim_player: AnimationPlayer = $"../AnimationPlayer"
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

enum SwingState {
	NONE,
	FORWARDS,
	BACKWARDS
}

const Sounds = {
	"WoodenAxe": preload("res://aud/axe.mp3"),
	"Fist": preload("res://aud/punch.wav"),
}

var swing_state = SwingState.NONE
var equipped_model: EquippableItem = null
var swing_hold = false

func _ready() -> void:
	anim_player.speed_scale = 2.0
	Signals.change_active_hotbar_slot.connect(change_equipped_model)

func change_equipped_model() -> void:
	var equipped = Inventory.inventory[Inventory.active_hotbar_index]
	equipped_model = null
	
	for item in get_children():
		if item is not EquippableItem: continue
		var real_deal = equipped and item.item_id == ItemRegistry.key_from_data(equipped.item_data)
		item.visible = real_deal and equipped
		if real_deal: equipped_model = item

	if not equipped_model:
		equipped_model = fist

func swing() -> void:
	if swing_state: return
	if not equipped_model: return
	
	equipped_model._on_click()
	
	var animation = {
		$WoodenAxe: "AxeChop",
		$WoodenPickaxe: "AxeChop",
	}.get(equipped_model, "Punch")
	
	var speed = {
		$WoodenAxe: 2.0
	}.get(equipped_model, 0.75)
	
	if animation == "Punch":
		fist.visible = true
	
	swing_state = SwingState.FORWARDS
	anim_player.play(animation, -1, speed)
	await anim_player.animation_finished
	
	if animation == "AxeChop":
		# HACK!!!
		swing_state = SwingState.BACKWARDS
		anim_player.play_backwards(animation)
		await anim_player.animation_finished
	
	swing_state = SwingState.NONE
	
	if animation == "Punch":
		fist.visible = false
	
	if swing_hold:
		# If we're still holding mouse1 or whatever, try to swing again
		swing()

func get_combat_recipient() -> CombatRecipient:
	for i in range(interact_cast.get_collision_count()):
		var collider = interact_cast.get_collider(i)
		
		if "combat" in collider.get_parent():
			collider = collider.get_parent()
		if "combat" not in collider: continue
		return collider.combat
	return null

func _swing_sound():
	if swing_state != SwingState.FORWARDS: return
	if not get_combat_recipient(): return
	
	audio_player.stream = Sounds.get(equipped_model.name, Sounds["Fist"])
	audio_player.pitch_scale = 1.0 + ((randf() - 0.5) * 0.2)
	audio_player.play()

func _at_mid_swing():
	if swing_state != SwingState.FORWARDS: return
	if not equipped_model: return
	
	if equipped_model.click_behavior == equipped_model.ClickBehavior.CUSTOM:
		equipped_model._on_use()
		return
	
	var combat = get_combat_recipient()
	if not combat: return
	
	var damage = {
		$WoodenAxe: 4.0,
	}.get(equipped_model, 1.5)
	combat.take_damage(CombatRecipient.DamageOrigin.PLAYER, damage)

func _input(event: InputEvent) -> void:
	if State.active_ui: return
	if State.build_mode: return
	
	if event is not InputEventMouseButton: return
	if event.button_index != MOUSE_BUTTON_LEFT: return
	
	swing_hold = event.pressed
	if not event.pressed: return
	
	swing()
