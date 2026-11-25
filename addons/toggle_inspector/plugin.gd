@tool
extends EditorPlugin

# :C: Cmd+Option+I rotates the Inspector's dock slot:
# FileSystem tab, then Inspector tab, then hidden.
# :C: hiding the slot is a workaround, not an official API;
# the editor may re-show it when the dock layout changes.

# i0 _input is the root of input catching, catches
# input events before everything else
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

	var file_system_tab := _tab_of(slot, EditorInterface.get_file_system_dock())
	var inspector_tab := _tab_of(slot, EditorInterface.get_inspector())
	if not slot.visible:
		slot.visible = true
		# :C: FileSystem may live in another slot; then show the Inspector.
		slot.current_tab = file_system_tab if file_system_tab >= 0 else inspector_tab
	elif slot.current_tab == file_system_tab:
		slot.current_tab = inspector_tab
	else:
		slot.visible = false

	# :C: the slot shares a split container with another slot.
	# :C: when every slot in it is hidden, hide the container too,
	# so the viewport gets the width back.
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


# i0i TabContainer is the horizontal strip that contains tabs
# :C: the dock slot is the first TabContainer above the Inspector.
# :C: found on each press,
# because the Inspector can be dragged to another slot.
func _inspector_slot() -> TabContainer:
	var node: Node = EditorInterface.get_inspector()
	while node != null and not node is TabContainer:
		node = node.get_parent()
	return node as TabContainer


# :C: the tab index of the slot's child holding this dock,
# or -1 when the dock is not in this slot.
func _tab_of(slot: TabContainer, dock: Node) -> int:
	while dock != null and dock.get_parent() != slot:
		dock = dock.get_parent()
	return slot.get_tab_idx_from_control(dock) if dock != null else -1
