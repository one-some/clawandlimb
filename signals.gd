@warning_ignore_start("unused_signal")
extends Node

signal load_save(save: WorldSave)
signal world_ready()

signal camera_shake(strength: float, origin: Vector3)
signal ui_blur(enable: bool)
signal ui_changed(active_ui: State.ActiveUI)
signal update_inventory_slot(slot_number: int)

signal tooltip_set_item(item_instance: ItemInstance)
signal tooltip_clear()

signal drop_item(item_instance: ItemInstance, position: Vector3)
signal try_pickup_item(item_instance: ItemInstance)
signal change_active_hotbar_slot()

signal change_player_health(combat: CombatRecipient, delta: float)
signal change_entity_health(combat: CombatRecipient, origin: CombatRecipient.DamageOrigin, og_health: float)

signal player_died()
# DO I HATE THIS!?!?!?
signal player_respawn_requested()

signal change_daylight_landmark(is_now_day: bool)
signal chunk_generated(chunk: VoxelMesh, chunk_pos: Vector3)
signal change_player_in_loading_chunk(in_there: bool)

signal update_3d_cursor_pos(pos: Vector3)
signal tp_player(pos: Vector3)
signal change_player_skin(skin: Texture)
