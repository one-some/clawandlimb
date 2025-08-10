extends Node3D

@onready var cam = %Camera3D
@onready var threed_cursor = %"3DCursor"
@onready var world = $".."
@onready var build_grid = %BuildGrid

const Wall = preload("res://wall.tscn")
const TestModel = preload("res://workbench.tscn")

# Yes this is terrible but I need time to think about it and sort it out :50
var candidate_build_mode = State.BuildMode.NONE
var active_constructable = null

func _ready() -> void:
	Signals.change_active_hotbar_slot.connect(_change_active_hotbar_slot)

func _change_active_hotbar_slot() -> void:
	var item = Inventory.active_item()
	if not item:
		candidate_build_mode = State.BuildMode.PLACE_NOTHING
		return
	
	var key = ItemRegistry.key_from_data(item.item_data)
	if key == "wooden_wall":
		candidate_build_mode = State.BuildMode.PLACE_WALL
	elif key == "workbench":
		candidate_build_mode = State.BuildMode.PLACE_MODEL
	else:
		candidate_build_mode = State.BuildMode.PLACE_NOTHING
	
	if State.build_mode != State.BuildMode.NONE:
		set_build_mode(candidate_build_mode)

func snapped_cursor_position() -> Vector3:
	var pos = threed_cursor.position

	if not active_constructable or not active_constructable.start_pos:
		return pos
	
	var start_pos = active_constructable.start_pos
	
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

func reset_building(init_start_pos: bool = false) -> void:
	print("Resetting with ", State.build_mode)
	
	if active_constructable:
		active_constructable = null
	
	if State.build_mode == State.BuildMode.PLACE_MODEL:
		active_constructable = TestModel.instantiate()
	elif State.build_mode == State.BuildMode.PLACE_WALL:
		active_constructable = Wall.instantiate()
	else:
		return
	
	# If u wanna continue girl.
	active_constructable.start_pos = snapped_cursor_position() if init_start_pos else null
	
	self.add_child(active_constructable)

func set_build_mode(build_mode: State.BuildMode) -> void:
	threed_cursor.visible = build_mode != State.BuildMode.PLACE_MODEL
	State.build_mode = build_mode
	reset_building()

func set_build_mode_enabled(mode: bool) -> void:
	State.build_mode = candidate_build_mode if mode else State.BuildMode.NONE
	threed_cursor.visible = mode
	build_grid.visible = mode
	
	if not mode and active_constructable:
		active_constructable.queue_free()
		active_constructable = null
	reset_building()

func commit_wall() -> void:
	assert(State.build_mode == State.BuildMode.PLACE_WALL)
	assert(active_constructable)
	
	# Committing the wall
	var end_pos = snapped_cursor_position()
	var int_end_pos = vec_floor_div(Vector2i(
		end_pos.x,
		end_pos.y
	), world.CHUNK_SIZE)
	
	var int_start_pos = vec_floor_div(Vector2i(
		active_constructable.start_pos.x,
		active_constructable.start_pos.z
	), world.CHUNK_SIZE)
	print(int_start_pos, " - ", int_end_pos)
	
	for coord in Geometry2D.bresenham_line(
		int_start_pos,
		int_end_pos
	):
		print("Updating ", coord)
		await world.update_chunk_collision(coord)
	
	# Finish up materialization of wall
	active_constructable.finalize()
	active_constructable = null
	reset_building(true)

func update_building() -> void:
	if State.build_mode == State.BuildMode.NONE: return
	if State.build_mode == State.BuildMode.PLACE_NOTHING: return
	
	var end_pos = snapped_cursor_position()
	active_constructable.set_end(end_pos)

func _process(delta: float) -> void:
	update_building()

func on_click() -> void:
	print(State.build_mode)
	
	match State.build_mode:
		State.BuildMode.PLACE_WALL:
			if active_constructable.start_pos:
				commit_wall()
				return
			
			active_constructable.set_start(threed_cursor.position)
		State.BuildMode.PLACE_MODEL:
			active_constructable = null
			reset_building(false)

func _input(event: InputEvent) -> void:
	if State.active_ui: return
	
	if event is InputEventKey:
		if Input.is_action_just_pressed("toggle_build"):
			set_build_mode_enabled(not State.build_mode)
		elif State.build_mode and Input.is_action_just_pressed("cancel"):
			set_build_mode_enabled(false)
		elif State.build_mode == State.BuildMode.PLACE_MODEL and Input.is_action_just_pressed("rotate_build") and active_constructable:
			active_constructable.rotation_degrees.y += 45.0

	elif event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT: return
		if not event.pressed: return
		on_click()
