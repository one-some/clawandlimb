extends Node3D

@onready var cam: Camera3D = %Camera3D
@onready var threed_cursor: MeshInstance3D = %"3DCursor"
@onready var build_grid: MeshInstance3D = %BuildGrid

const Wall = preload("res://build/wall.tscn")
const TestModel = preload("res://build/workbench.tscn")
const Door = preload("res://build/door.tscn")
const TerrainDestroyer = preload("res://build/terrain_destroyer.tscn")
const Tile = preload("res://tile.tscn")

var down_click_tap = false
var down_click_pos = null
var active_constructable: Constructable = null

func _ready() -> void:
	set_build_mode(State.build_mode)
	Signals.change_active_hotbar_slot.connect(_change_active_hotbar_slot)
	Signals.update_3d_cursor_pos.connect(_on_3d_cursor_pos_update)

func _change_active_hotbar_slot() -> void:
	var item = Inventory.active_item()
	
	if not item:
		set_build_mode(State.BuildMode.NONE)
		return
	
	var key = item.key()
	if key in ["wooden_wall", "stone_wall"]:
		set_build_mode(State.BuildMode.PLACE_WALL)
	elif key == "workbench":
		set_build_mode(State.BuildMode.PLACE_MODEL)
	elif key == "wooden_door":
		set_build_mode(State.BuildMode.PLACE_DOOR)
	elif key == "wooden_shovel":
		set_build_mode(State.BuildMode.REMOVE_TERRAIN)
	elif key == "plank_floor":
		set_build_mode(State.BuildMode.PLACE_TILE)
	else:
		set_build_mode(State.BuildMode.NONE)
	
func snapped_cursor_position() -> Vector3:
	var pos = threed_cursor.position

	if not active_constructable or active_constructable.start_pos == null:
		return pos
	
	var start_pos = active_constructable.start_pos
	pos.y = start_pos.y
	
	var delta = start_pos - pos
	if abs(delta.x) > abs(delta.z):
		pos.z = start_pos.z
	else:
		pos.x = start_pos.x
	return pos

# TODO: Optional start_pos
func set_build_mode(build_mode: State.BuildMode, start_pos: Variant = null) -> void:
	print("Setting build mode to ", build_mode)
	if build_mode == 1:
		breakpoint
	
	threed_cursor.visible = build_mode not in [
		State.BuildMode.NONE,
		State.BuildMode.PLACE_MODEL
	]
	State.build_mode = build_mode
	build_grid.visible = build_mode != State.BuildMode.NONE
	
	if active_constructable:
		remove_child(active_constructable)
		
		# HACK: This freezes the game until chunks are done generating lol
		# spent 8 hours trying to debug why but didn't really get anywhere. We
		# just gonna let it happen
		#active_constructable.free()
		#active_constructable.queue_free()
		active_constructable = null
	
	match State.build_mode:
		State.BuildMode.PLACE_MODEL:
			active_constructable = TestModel.instantiate()
		State.BuildMode.PLACE_WALL:
			active_constructable = Wall.instantiate()
			var key = Inventory.active_item().key()
			active_constructable.wall_type = {
				"wooden_wall": "wood",
				"stone_wall": "stone"
			}[key]
		State.BuildMode.PLACE_DOOR:
			active_constructable = Door.instantiate()
		State.BuildMode.PLACE_TILE:
			active_constructable = Tile.instantiate()
		State.BuildMode.REMOVE_TERRAIN:
			active_constructable = TerrainDestroyer.instantiate()
		_:
			return
	
	if start_pos:
		# If u wanna continue girl.
		active_constructable.set_start(start_pos)
	
	self.add_child(active_constructable)
	update_building()

func update_building() -> void:
	if not active_constructable: return
	if State.build_mode == State.BuildMode.NONE: return
	if State.build_mode == State.BuildMode.PLACE_NOTHING: return
	
	var end_pos = snapped_cursor_position() if not active_constructable.allow_freehand else threed_cursor.position
	active_constructable.set_end(end_pos)

func _on_3d_cursor_pos_update(pos: Vector3) -> void:
	update_building()
	
	if down_click_pos:
		print("OMG DRAMA")
		# We have just started MOVING in between a mouse down and a mouse up. DRAMA!!!
		active_constructable.set_start(down_click_pos)
		down_click_pos = null
	

func on_left_down() -> void:
	if active_constructable.one_and_done: return
	if active_constructable.start_pos: return
	
	print("Left down")
	# Will the left up event remain faithful? Or will he move on...?
	down_click_pos = threed_cursor.position
	down_click_tap = false 

func on_left_up() -> void:
	print("up")
	if active_constructable.one_and_done:
		active_constructable.finalize()
		active_constructable = null
		_change_active_hotbar_slot()
		return
	
	if active_constructable.start_pos:
		# We're done with all that childish stuff. We're together now. And we're
		# also finishing up the build
		
		var new_start = active_constructable.end_pos if (
			State.build_mode == State.BuildMode.PLACE_WALL and down_click_tap
		) else null
		down_click_pos = null
		
		active_constructable.finalize()
		active_constructable = null
		set_build_mode(State.build_mode, new_start)
		return
	
	if down_click_pos:
		# Of course I remained faithful, my darling. Now let's start a beautiful
		# click-based life together.
		active_constructable.set_start(down_click_pos)
		down_click_pos = null
		down_click_tap = true
		return
	
	assert(false, "How did we get here")
	

func on_mouse_left(down: bool) -> void:
	if State.build_mode in [State.BuildMode.NONE, State.BuildMode.PLACE_NOTHING]:
		return
	
	if down:
		on_left_down()
	else:
		on_left_up()
	
	return
	
	if down:
		print("We're down")
		down_click_pos = threed_cursor.position 
		return
		
	print("We're up")
	# Going up
	if down_click_pos == threed_cursor.position:
		print("Old way")
		# We are doing a "click once start, click once end" deal. No dragging.
		if active_constructable.start_pos == null and not active_constructable.one_and_done:
			
			print("[click] No start pos. Setting.")
			return
	else:
		# Dragging
		active_constructable.set_start(down_click_pos)
		print("Drag end. From ", down_click_pos, " to ", threed_cursor.position)
	
	
	


func _input(event: InputEvent) -> void:
	if State.active_ui: return
	
	if event is InputEventKey:
		if (
			Input.is_action_just_pressed("rotate_build") 
			and active_constructable
			and State.build_mode in [State.BuildMode.PLACE_MODEL, State.BuildMode.PLACE_DOOR]
		):
			active_constructable.rotation_degrees.y += 45.0

	elif event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT: return
		on_mouse_left(event.pressed)
