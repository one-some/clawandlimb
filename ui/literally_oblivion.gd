extends Label

func _ready() -> void:
	Signals.change_player_in_loading_chunk.connect(func(in_there): self.visible = in_there)
