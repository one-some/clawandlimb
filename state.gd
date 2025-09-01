extends Node

var active_save: WorldSave

enum ActiveUI {
	NONE = 0,
	INVENTORY,
	DEAD
}
var active_ui: ActiveUI = ActiveUI.NONE

func set_active_ui(ui: ActiveUI) -> void:
	active_ui = ui
	Signals.ui_changed.emit(active_ui)

enum BuildMode {
	NONE = 0,
	PLACE_NOTHING,
	PLACE_WALL,
	PLACE_MODEL,
	PLACE_DOOR,
	PLACE_TILE,
	REMOVE_TERRAIN
}
var build_mode: BuildMode = BuildMode.NONE

var chunk_manager: ChunkManager
@warning_ignore("unused_private_class_variable")
var _hack_t2d: Texture2DArray
var player: CharacterBody3D
