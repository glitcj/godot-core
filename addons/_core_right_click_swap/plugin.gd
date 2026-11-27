@tool
extends EditorPlugin


# :C: flipping Alt in place works because the 2D view
# reads this same event object after _input.
func _input(event: InputEvent) -> void:
	var right_click := event as InputEventMouseButton
	if right_click == null or right_click.button_index != MOUSE_BUTTON_RIGHT: return
	if not _is_over_2d_viewport(right_click.position): return
	right_click.alt_pressed = not right_click.alt_pressed


# :C: limits the swap to the 2D view, so right-click
# stays normal in docks, the script editor and 3D.
func _is_over_2d_viewport(window_position: Vector2) -> bool:
	var viewport_2d_container := EditorInterface.get_editor_viewport_2d().get_parent() as Control
	if viewport_2d_container == null or not viewport_2d_container.is_visible_in_tree(): return false
	return viewport_2d_container.get_global_rect().has_point(window_position)
