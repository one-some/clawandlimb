extends Node

signal camera_shake(strength: float, origin: Vector3)
signal ui_blur(enable: bool)
signal update_inventory_slot(slot_number: int)

signal tooltip_set_item(item_instance: ItemInstance)
signal tooltip_clear()

signal drop_item(item_instance: ItemInstance, position: Vector3)
signal try_pickup_item(item_instance: ItemInstance)
