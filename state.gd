extends Node

enum ActiveUI {
	NONE = 0,
	INVENTORY,
	DEAD
}
var active_ui: ActiveUI = ActiveUI.NONE
var build_mode = false
