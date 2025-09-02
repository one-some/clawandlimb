extends Control

@onready var world_name_box: LineEdit = $VBoxContainer/WorldName
@onready var world_seed_box: LineEdit = $VBoxContainer/WorldSeed
@onready var world_type_selector: MenuButton = $VBoxContainer/WorldType

const WorldTypes = {
	"Normal": VoxelMesh.WORLDGEN_KITTY,
	"Flat": VoxelMesh.WORLDGEN_FLAT
}
const Main = preload("res://main.tscn")

var world_type: VoxelMesh.Worldgen = WorldTypes.values()[0]

func _ready() -> void:
	for label in WorldTypes:
		world_type_selector.get_popup().add_item(label)

	world_type_selector.get_popup().id_pressed.connect(_on_world_type_selected)
	_on_world_type_selected(0)

func get_mad_at(who: Control) -> void:
	who.modulate = Color.DARK_RED
	var tween = create_tween()
	tween.tween_property(who, "modulate", Color.WHITE, 0.4)
	tween.play()

func _on_world_type_selected(id: int) -> void:
	var label = WorldTypes.keys()[id]
	world_type_selector.text = "World Type: %s" % label
	world_type = WorldTypes.values()[id]


func _on_new_world_pressed() -> void:
	for control in [world_name_box, world_seed_box]:
		if control.text.strip_edges(): continue
		get_mad_at(control)
		return
	
	if not world_name_box.text.is_valid_filename():
		get_mad_at(world_name_box)
		return
	
	var save = WorldSave.create(
		world_name_box.text,
		world_type,
		world_seed_box.text
	)
	
	State.active_save = save
	get_tree().change_scene_to_packed(Main)
	
