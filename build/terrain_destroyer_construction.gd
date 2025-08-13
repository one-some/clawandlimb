extends Constructable

@onready var box: BoxMesh = $TerrainDestroyer.mesh

func set_end(pos: Vector3) -> void:
	if not start_pos:
		return
		
	end_pos = pos
	
	box.size = (end_pos - start_pos).abs()
	self.global_position = (end_pos + start_pos) / 2.0

func finalize() -> void:
	var start = start_pos.min(end_pos)
	var size = (end_pos - start_pos).abs()
	
	# Shift up one (HACK)
	size.y += 2
	start.y += 1
	
	var end = start + size
	
	var affected_chunks = []
	for x in range(start.x, end.x):
		for y in range(start.y, end.y):
			for z in range(start.z, end.z):
				var pos = Vector3(x, y, z)
				
				var modified = State.chunk_manager.set_density_global(pos, -1.0)
				
				for chunk_pos in modified:
					if chunk_pos in affected_chunks: continue
					affected_chunks.append(chunk_pos)
	
	#for chunk_pos in affected_chunks.duplicate():
		#for dx in [-1, 0, 1]:
			#for dy in [-1, 0, 1]:
				#for dz in [-1, 0, 1]:
					#print("AHHH")
					#var offset = Vector3(dx, dy, dz)
					#if not offset: continue
					#var neighbor_pos = chunk_pos + offset
					#if neighbor_pos not in affected_chunks: affected_chunks.append(neighbor_pos)


	for chunk_pos in affected_chunks:
		if chunk_pos not in State.chunk_manager.chunks: continue
		print("Regenerating", chunk_pos)
		State.chunk_manager.chunks[chunk_pos].generate_mesh()
		#State.chunk_manager.ids.append(WorkerThreadPool.add_task(
			#State.chunk_manager.chunks[chunk_pos].generate_mesh
		#))

		#.chunks[chunk_pos].generate_mesh()
	
	self.queue_free()
	
