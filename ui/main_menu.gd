extends Control

@onready var menus = $Menus

func _ready() -> void:
	show_menu($Menus/Main)

func show_menu(menu: Control) -> void:
	for child in menus.get_children():
		child.visible = child == menu

func _on_worlds_pressed() -> void:
	show_menu($Menus/Worlds)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_new_world_pressed() -> void:
	show_menu($Menus/NewWorld)

func _on_back_pressed() -> void:
	show_menu($Menus/Main)
