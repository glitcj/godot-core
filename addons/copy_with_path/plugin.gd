
@tool
extends EditorPlugin


func _input(event: InputEvent) -> void:
		var key := event as InputEventKey
		if key == null or not key.pressed or key.echo:
				return
		# Cmd + Option + L
		if key.physical_keycode != KEY_L or not key.meta_pressed or not key.alt_pressed:
				return

		var script_editor := EditorInterface.get_script_editor()
		var script := script_editor.get_current_script()
		var current := script_editor.get_current_editor()
		if script == null or current == null:
				return
		var code := current.get_base_editor() as CodeEdit
		if code == null or not code.has_focus():
				return


		var start := code.get_caret_line()
		var end := start
		if code.has_selection():
				start = code.get_selection_from_line()
				end = code.get_selection_to_line()
				# a selection ending at column 0 shouldn't include that line
				if end > start and code.get_selection_to_column() == 0:
						end -= 1

		var lines: PackedStringArray = []
		for i in range(start, end + 1):
				lines.append("%d: %s" % [i + 1, code.get_line(i)])

		var path := ProjectSettings.globalize_path(script.resource_path)
		var line_range := str(start + 1) if start == end else "%d-%d" % [start + 1, end + 1]
		DisplayServer.clipboard_set("%s:%s\n%s" % [path, line_range, "\n".join(lines)])
		get_viewport().set_input_as_handled()
		
