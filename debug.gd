extends Node

func _input(event: InputEvent) -> void:
	if event is not InputEventKey: return
	if not event.is_pressed(): return
	if not event.is_action("debug_profile"): return
	
	#perf record -F 99 -p $(pidof godot) --call-graph dwarf sleep 10
	var code = OS.create_process(
		"perf",
		[
			"record",
			"-F",
			"99",
			"-p",
			str(OS.get_process_id()),
			"--call-graph",
			"dwarf",
			"-o",
			"/home/claire/clawandlimb_prof.data",
			"sleep",
			"3"
		],
	)
