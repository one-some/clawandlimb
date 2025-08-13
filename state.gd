extends Node

enum ActiveUI {
	NONE = 0,
	INVENTORY,
	DEAD
}
var active_ui: ActiveUI = ActiveUI.NONE

enum BuildMode {
	NONE = 0,
	PLACE_NOTHING,
	PLACE_WALL,
	PLACE_MODEL,
	PLACE_DOOR,
	REMOVE_TERRAIN
}
var build_mode: BuildMode = BuildMode.NONE

var _hack_tile_images: Array[Image] = []
var chunk_manager: ChunkManager
