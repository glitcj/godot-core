@tool
extends EditorScript

# Scans every TileMapLayer and deprecated TileMap in the currently edited scene (including ones inside
# instanced sub-scenes) for cells referencing a source/atlas coord that no longer
# exists in the TileSet, plus the TileSet's saved patterns.
# Set ERASE_INVALID to true to delete bad cells (save the scene after).
# Cells inside instanced scenes are reported but never erased here — open that
# scene and run the script there instead, so the fix lands in the source file.

const ERASE_INVALID := false

func _run() -> void:
	var root := get_scene()
	if root == null:
		push_error("No scene open in the editor.")
		return

	var invalid_count := 0
	var checked_tilesets: Array[TileSet] = []

	# owned=false so layers inside instanced scenes are included too
	for layer: TileMapLayer in root.find_children("*", "TileMapLayer", true, false):
		if layer.tile_set == null:
			push_warning("[%s] has no TileSet assigned, skipping." % layer.name)
			continue

		var editable := layer.owner == root or layer == root
		var foreign_scene := "" if editable else _source_scene(layer)

		for cell in layer.get_used_cells():
			var reason := _cell_problem(layer.tile_set, layer.get_cell_source_id(cell), layer.get_cell_atlas_coords(cell))
			if reason == "":
				continue
			invalid_count += 1
			if foreign_scene:
				print("[%s] invalid cell at %s: %s — fix it in %s" % [root.get_path_to(layer), cell, reason, foreign_scene])
			else:
				print("[%s] invalid cell at %s: %s" % [root.get_path_to(layer), cell, reason])
				if ERASE_INVALID: layer.erase_cell(cell)

		if not checked_tilesets.has(layer.tile_set):
			checked_tilesets.append(layer.tile_set)
			invalid_count += _check_patterns(layer.tile_set)

	# Deprecated TileMap nodes (pre-TileMapLayer class, e.g. converted Godot 3 scenes)
	for tilemap: TileMap in root.find_children("*", "TileMap", true, false):
		if tilemap.tile_set == null:
			continue

		var editable := tilemap.owner == root or tilemap == root
		var foreign_scene := "" if editable else _source_scene(tilemap)

		for tm_layer in tilemap.get_layers_count():
			for cell in tilemap.get_used_cells(tm_layer):
				var reason := _cell_problem(tilemap.tile_set, tilemap.get_cell_source_id(tm_layer, cell), tilemap.get_cell_atlas_coords(tm_layer, cell))
				if reason == "":
					continue
				invalid_count += 1
				if foreign_scene:
					print("[%s] (deprecated TileMap, layer %d) invalid cell at %s: %s — fix it in %s" % [root.get_path_to(tilemap), tm_layer, cell, reason, foreign_scene])
				else:
					print("[%s] (deprecated TileMap, layer %d) invalid cell at %s: %s" % [root.get_path_to(tilemap), tm_layer, cell, reason])
					if ERASE_INVALID: tilemap.erase_cell(tm_layer, cell)

		if not checked_tilesets.has(tilemap.tile_set):
			checked_tilesets.append(tilemap.tile_set)
			invalid_count += _check_patterns(tilemap.tile_set)

	if invalid_count == 0:
		print("No invalid tiles found.")
	else:
		print("%d invalid cell(s) found%s." % [invalid_count, ", erased where editable — save the scene" if ERASE_INVALID else ""])

func _cell_problem(tile_set: TileSet, source_id: int, atlas_coords: Vector2i) -> String:
	if not tile_set.has_source(source_id):
		return "unknown source id %d" % source_id
	var source := tile_set.get_source(source_id)
	if source is TileSetAtlasSource and not source.has_tile(atlas_coords):
		return "no tile at atlas coords %s" % atlas_coords
	return ""

func _check_patterns(tile_set: TileSet) -> int:
	var invalid_count := 0
	for i in tile_set.get_patterns_count():
		var pattern := tile_set.get_pattern(i)
		for cell in pattern.get_used_cells():
			var reason := _cell_problem(tile_set, pattern.get_cell_source_id(cell), pattern.get_cell_atlas_coords(cell))
			if reason == "":
				continue
			invalid_count += 1
			print("[TileSet %s] pattern %d has invalid cell at %s: %s" % [tile_set.resource_path, i, cell, reason])
	return invalid_count

func _source_scene(node: Node) -> String:
	var n := node
	while n != null:
		if n.scene_file_path != "":
			return n.scene_file_path
		n = n.get_owner()
	return "(unknown scene)"
