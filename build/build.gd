extends Node3D

@onready var cam = %Camera3D
@onready var threed_cursor = %"3DCursor"
@onready var build_grid = %BuildGrid

const Wall = preload("res://build/wall.tscn")
const TestModel = preload("res://build/workbench.tscn")
const Door = preload("res://build/door.tscn")
const TerrainDestroyer = preload("res://build/terrain_destroyer.tscn")
const Tile = preload("res://tile.tscn")

var active_constructable: Constructable = null

func _ready() -> void:
	set_build_mode(State.build_mode)
	Signals.change_active_hotbar_slot.connect(_change_active_hotbar_slot)

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

func vec_floor_div(v: Vector2i, div: int) -> Vector2i:
	return Vector2i(
		floor(v.x / float(div)),
		floor(v.y / float(div))
	)

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
		#print("MAIN THREAD: Queuing 'active_constructable' for deletion.")
		#print(active_constructable.name)
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

func commit_wall() -> void:
	assert(State.build_mode == State.BuildMode.PLACE_WALL)
	assert(active_constructable)
	
	# Committing the wall
	var int_end_pos = vec_floor_div(Vector2i(
		active_constructable.end_pos.x,
		active_constructable.end_pos.z
	), ChunkData.CHUNK_SIZE)
	
	var int_start_pos = vec_floor_div(Vector2i(
		active_constructable.start_pos.x,
		active_constructable.start_pos.z
	), ChunkData.CHUNK_SIZE)
	#print(int_start_pos, " - ", int_end_pos)
	
	for coord in Geometry2D.bresenham_line(
		int_start_pos,
		int_end_pos
	):
		print("Updating ", coord)
		State.chunk_manager.update_chunk_collision(coord)
	
	# Finish up materialization of wall
	active_constructable.finalize()

func update_building() -> void:
	if not active_constructable: return
	if State.build_mode == State.BuildMode.NONE: return
	if State.build_mode == State.BuildMode.PLACE_NOTHING: return
	
	var end_pos = snapped_cursor_position() if not active_constructable.allow_freehand else threed_cursor.position
	active_constructable.set_end(end_pos)

func _process(delta: float) -> void:
	update_building()

func on_click() -> void:
	if State.build_mode in [State.BuildMode.NONE, State.BuildMode.PLACE_NOTHING]:
		return
	
	#if not active_constructable:
		#reset_building()
		#print("[click] No active constructable. Resetting.")
		#return
	
	if active_constructable.start_pos == null and not active_constructable.one_and_done:
		active_constructable.set_start(threed_cursor.position)
		print("[click] No start pos. Setting.")
		return
	
	match State.build_mode:
		State.BuildMode.PLACE_WALL:
			if active_constructable.start_pos:
				var new_start = active_constructable.end_pos
				commit_wall()
				active_constructable = null
				set_build_mode(State.BuildMode.PLACE_WALL, new_start)
				return
		State.BuildMode.REMOVE_TERRAIN:
			if active_constructable.start_pos:
				active_constructable.finalize()
				active_constructable = null
				set_build_mode(State.BuildMode.REMOVE_TERRAIN)
				return
		_:
			active_constructable.finalize()
			active_constructable = null
			_change_active_hotbar_slot()

func _input(event: InputEvent) -> void:
	if State.active_ui: return
	
	if event is InputEventKey:
		#if Input.is_action_just_pressed("toggle_build"):
			#set_build_mode_enabled(not State.build_mode)
		if State.build_mode and Input.is_action_just_pressed("cancel"):
			set_build_mode(State.BuildMode.NONE)
		elif (
			Input.is_action_just_pressed("rotate_build") 
			and active_constructable
			and State.build_mode in [State.BuildMode.PLACE_MODEL, State.BuildMode.PLACE_DOOR]
		):
			active_constructable.rotation_degrees.y += 45.0

	elif event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT: return
		if not event.pressed: return
		on_click()
