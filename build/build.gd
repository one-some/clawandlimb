extends Node3D

@onready var cam: Camera3D = %Camera3D
@onready var threed_cursor: MeshInstance3D = %"3DCursor"
@onready var build_grid: MeshInstance3D = %BuildGrid

var down_click_tap = false
var down_click_pos = null
var active_constructable: Constructable = null

func _ready() -> void:
	Save.register_handler("build", to_json, from_json)
	
	set_build_mode(State.build_mode, null)
	Signals.change_active_hotbar_slot.connect(_change_active_hotbar_slot)
	Signals.update_3d_cursor_pos.connect(_on_3d_cursor_pos_update)

func to_json() -> Array:
	var out = []
	
	for constructable: Constructable in self.get_children():
		assert(constructable.scene_file_path)
		out.append(constructable.to_json())
	
	return out

func from_json(data: Array) -> void:
	for construction_data in data:
		print("DDD", construction_data)
		var instance: Node3D = load(construction_data["scene_path"]).instantiate()
		self.add_child(instance)
		#await instance.ready
		print("Ready")
		instance.from_json(construction_data)

func instantiate_selected_constructable() -> Constructable:
	var item = Inventory.active_item()
	if not item:
		return null
	
	var constructable_scene = item.item_data.item_constructable
	if not constructable_scene:
		#print("No constructable")
		set_build_mode(State.BuildMode.NONE, null)
		return null
	return constructable_scene.instantiate()

func _change_active_hotbar_slot() -> void:
	var constructable = instantiate_selected_constructable()
	if not constructable: 
		set_build_mode(State.BuildMode.NONE, null)
		return
	set_build_mode(constructable.build_mode, constructable)
	
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
func set_build_mode(build_mode: State.BuildMode, constructable: Constructable, start_pos: Variant = null) -> void:
	#print("Setting build mode to ", build_mode)
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
	
	active_constructable = constructable
	
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
		# We have just started MOVING in between a mouse down and a mouse up. DRAMA!!!
		active_constructable.set_start(down_click_pos)
		down_click_pos = null
	

func on_left_down() -> void:
	if active_constructable.is_one_and_done(): return
	if active_constructable.start_pos: return
	
	# Will the left up event remain faithful? Or will he move on...?
	down_click_pos = threed_cursor.position
	down_click_tap = false 

func on_left_up() -> void:
	if active_constructable.is_one_and_done():
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
		
		if active_constructable.end_pos == null:
			active_constructable.set_end(threed_cursor.position)
		
		active_constructable.finalize()
		active_constructable = null
		
		var new_constructable = instantiate_selected_constructable()
		set_build_mode(State.build_mode, new_constructable, new_start)
		return
	
	if down_click_pos:
		# Of course I remained faithful, my darling. Now let's start a beautiful
		# click-based life together.
		active_constructable.set_start(down_click_pos)
		down_click_pos = null
		down_click_tap = true
		return
	
	# DISCOVERY: Clicking down on another tool and up on us gets us here
	#assert(false, "How did we get here")
	

func on_mouse_left(down: bool) -> void:
	if State.build_mode in [State.BuildMode.NONE, State.BuildMode.PLACE_NOTHING]:
		return
	
	if down:
		on_left_down()
	else:
		on_left_up()
	
	return


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
