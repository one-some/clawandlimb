extends Node3D

@onready var cam = %Camera3D
@onready var threed_cursor = %"3DCursor"
@onready var build_grid = %BuildGrid

const Wall = preload("res://build/wall.tscn")
const TestModel = preload("res://build/workbench.tscn")
const Door = preload("res://build/door.tscn")
const TerrainDestroyer = preload("res://build/terrain_destroyer.tscn")

var active_constructable: Constructable = null

func _ready() -> void:
	Signals.change_active_hotbar_slot.connect(_change_active_hotbar_slot)

func _change_active_hotbar_slot() -> void:
	var item = Inventory.active_item()
	
	if not item:
		set_build_mode(State.BuildMode.PLACE_NOTHING)
		return
	
	var key = ItemRegistry.key_from_data(item.item_data)
	if key == "wooden_wall":
		set_build_mode(State.BuildMode.PLACE_WALL)
	elif key == "workbench":
		set_build_mode(State.BuildMode.PLACE_MODEL)
	elif key == "wooden_door":
		set_build_mode(State.BuildMode.PLACE_DOOR)
	elif key == "wooden_shovel":
		set_build_mode(State.BuildMode.REMOVE_TERRAIN)
	else:
		set_build_mode(State.BuildMode.PLACE_NOTHING)
	
func snapped_cursor_position() -> Vector3:
	var pos = threed_cursor.position

	if not active_constructable or not active_constructable.start_pos:
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

func reset_building(init_start_pos = null) -> void:
	print("Resetting with ", State.build_mode)
	
	if active_constructable:
		print("[reset] queue free and null")
		active_constructable.queue_free()
		active_constructable = null
	
	print("ok")
	
	if State.build_mode == State.BuildMode.PLACE_MODEL:
		print("[reset] tst")
		active_constructable = TestModel.instantiate()
	elif State.build_mode == State.BuildMode.PLACE_WALL:
		print("[reset] wall")
		active_constructable = Wall.instantiate()
	elif State.build_mode == State.BuildMode.PLACE_DOOR:
		print("[reset] door")
		active_constructable = Door.instantiate()
	elif State.build_mode == State.BuildMode.REMOVE_TERRAIN:
		print("[reset] r_terr")
		active_constructable = TerrainDestroyer.instantiate()
	else:
		print("Nothing..?")
		return
	
	# If u wanna continue girl.
	#active_constructable.start_pos = snapped_cursor_position() if init_start_pos else null
	active_constructable.start_pos = init_start_pos
	
	print("BLEHHH")
	self.add_child(active_constructable)

func set_build_mode(build_mode: State.BuildMode) -> void:
	threed_cursor.visible = build_mode not in [
		State.BuildMode.PLACE_MODEL
		State.BuildMode.
	]
	State.build_mode = build_mode
	
	threed_cursor.visible = mode
	build_grid.visible = mode
	
	if not mode and active_constructable:
		active_constructable.queue_free()
		active_constructable = null
	
	print("Whatt..")
	reset_building()
	print("OK Ugh")
	

func commit_wall() -> void:
	assert(State.build_mode == State.BuildMode.PLACE_WALL)
	assert(active_constructable)
	
	# Committing the wall
	var int_end_pos = vec_floor_div(Vector2i(
		active_constructable.end_pos.x,
		active_constructable.end_pos.y
	), ChunkData.CHUNK_SIZE)
	
	var int_start_pos = vec_floor_div(Vector2i(
		active_constructable.start_pos.x,
		active_constructable.start_pos.z
	), ChunkData.CHUNK_SIZE)
	print(int_start_pos, " - ", int_end_pos)
	
	for coord in Geometry2D.bresenham_line(
		int_start_pos,
		int_end_pos
	):
		print("Updating ", coord)
		State.chunk_manager.update_chunk_collision(coord)
	
	# Finish up materialization of wall
	active_constructable.finalize()
	var end_pos = active_constructable.end_pos
	active_constructable = null
	reset_building(end_pos)

func allow_freehand() -> bool:
	return State.build_mode == State.BuildMode.REMOVE_TERRAIN

func update_building() -> void:
	print("Upt")
	if not active_constructable: return
	if State.build_mode == State.BuildMode.NONE: return
	if State.build_mode == State.BuildMode.PLACE_NOTHING: return
	
	var end_pos = snapped_cursor_position() if not allow_freehand() else threed_cursor.position
	active_constructable.set_end(end_pos)

func _process(delta: float) -> void:
	update_building()

func on_click() -> void:
	if State.build_mode in [State.BuildMode.NONE, State.BuildMode.PLACE_NOTHING]:
		return
	
	if not active_constructable:
		reset_building()
		print("[click] No active constructable. Resetting.")
		return
	
	if not active_constructable.start_pos and not active_constructable.one_and_done:
		active_constructable.set_start(threed_cursor.position)
		print("[click] No start pos. Setting.")
		return
	
	match State.build_mode:
		State.BuildMode.PLACE_WALL:
			if active_constructable.start_pos:
				commit_wall()
				return
		State.BuildMode.REMOVE_TERRAIN:
			if active_constructable.start_pos:
				active_constructable.finalize()
				active_constructable = null
				reset_building()
				return
		_:
			print("Bruuuuu")
			active_constructable.finalize()
			active_constructable = null
			reset_building()

func _input(event: InputEvent) -> void:
	if State.active_ui: return
	
	if event is InputEventKey:
		if Input.is_action_just_pressed("toggle_build"):
			set_build_mode_enabled(not State.build_mode)
		elif State.build_mode and Input.is_action_just_pressed("cancel"):
			set_build_mode_enabled(false)
			print("Post.")
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
