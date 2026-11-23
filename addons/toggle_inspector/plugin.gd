@tool
extends EditorPlugin

# CLAUDE: Cmd+Option+I shows/hides the dock column holding the Inspector.
# This is a plugin because editor shortcuts can't be set per project through
# [editor_overrides] in project.godot, and the built-in "Open Inspector Dock"
# shortcut only opens the dock, it never hides it.
# Toggling the slot's visibility is a workaround, not an official API: the
# editor may re-show the column when the dock layout changes (press again).


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	# Cmd + Option + I
	if key.physical_keycode != KEY_I or not key.meta_pressed or not key.alt_pressed:
		return

	var slot := _inspector_slot()
	if slot == null:
		return
	slot.visible = not slot.visible

	# CLAUDE: the slot usually sits in a split container with a second slot
	# below it. If every sibling is hidden too, hide that parent as well so
	# the column gives its width back to the viewport instead of leaving a gap.
	var column := slot.get_parent() as SplitContainer
	if column != null:
		var any_visible := false
		for child in column.get_children():
			var control := child as Control
			if control != null and control.visible:
				any_visible = true
				break
		column.visible = any_visible

	get_viewport().set_input_as_handled()


# CLAUDE: the dock slot is the first TabContainer above the Inspector; found
# on each press because the Inspector can be dragged to another slot.
func _inspector_slot() -> Control:
	var node: Node = EditorInterface.get_inspector()
	while node != null and not node is TabContainer:
		node = node.get_parent()
	return node as Control
