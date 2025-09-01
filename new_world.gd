extends Control

@onready var world_name_box: LineEdit = $VBoxContainer/WorldName
@onready var world_seed_box: LineEdit = $VBoxContainer/WorldSeed
@onready var world_type_selector: MenuButton = $VBoxContainer/WorldType

const WORLD_TYPES = {
	"Normal": VoxelMesh.WORLDGEN_KITTY,
	"Flat": VoxelMesh.WORLDGEN_FLAT
}

var world_type: VoxelMesh.Worldgen

func _ready() -> void:
	for label in WORLD_TYPES:
		world_type_selector.get_popup().add_item(label)

	world_type_selector.get_popup().id_pressed.connect(_on_world_type_selected)
	_on_world_type_selected(0)

func get_mad_at(who: Control) -> void:
	who.modulate = Color.DARK_RED
	var tween = create_tween()
	tween.tween_property(who, "modulate", Color.WHITE, 0.4)
	tween.play()

func _on_world_type_selected(id: int) -> void:
	var label = WORLD_TYPES.keys()[id]
	world_type_selector.text = "World Type: %s" % label
	world_type = WORLD_TYPES.values()[id]


func _on_new_world_pressed() -> void:
	for control in [world_name_box, world_seed_box]:
		if control.text.strip_edges(): continue
		get_mad_at(control)
		return
	
	OS.alert("Ok do this later rofl")
