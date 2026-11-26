@tool
extends EditorPlugin

# :C: F12 or Cmd+Option+I steps through the tabs
# of the Inspector's dock slot, then hides the slot.
# :C: hiding the slot is a workaround, not an official API;
# the editor may re-show it when the dock layout changes.
# :C: selecting a node brings the Inspector forward.


# :C: no disconnect needed;
# Godot drops the connection when this plugin is freed.
func _enter_tree() -> void:
	EditorInterface.get_selection().selection_changed.connect(_show_inspector)


# i0 _input is the root of input catching, catches
# input events before everything else
func _input(event: InputEvent) -> void:
	_input_inspector_toggle(event)




func _input_dock_toggle(event : InputEvent):
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo: return
	# F11
	if key.physical_keycode != KEY_F11: return
	
	# i0i grab bottom dock
	# o-o toggle loop through [ show bottom dock > maximise dock > hide dock ]
	
	


func _input_inspector_toggle(event : InputEvent):
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo: return
	# F12, or Cmd + Option + I
	var is_cmd_option_i := key.physical_keycode == KEY_I and key.meta_pressed and key.alt_pressed
	if key.physical_keycode != KEY_F12 and not is_cmd_option_i: return

	var slot := _inspector_slot()
	if slot == null: return

	if not slot.visible:
		slot.visible = true
		slot.current_tab = 0
	elif slot.current_tab < slot.get_tab_count() - 1:
		slot.current_tab += 1
	else:
		slot.visible = false

	_sync_column(slot)
	get_viewport().set_input_as_handled()


# :C: selection_changed also fires on deselect, which is ignored.
func _show_inspector() -> void:
	if EditorInterface.get_selection().get_selected_nodes().is_empty(): return
	var slot := _inspector_slot()
	if slot == null: return

	# :C: the Inspector's tab is the one that contains it.
	var inspector := EditorInterface.get_inspector()
	for tab in slot.get_tab_count():
		var tab_control := slot.get_tab_control(tab)
		if tab_control == inspector or tab_control.is_ancestor_of(inspector): slot.current_tab = tab
	slot.visible = true
	_sync_column(slot)


# :C: the slot shares a split container with another slot.
# :C: when every slot in it is hidden, hide the container too,
# so the viewport gets the width back.
func _sync_column(slot: TabContainer) -> void:
	var column := slot.get_parent() as SplitContainer
	if column != null:
		column.visible = column.get_children().any(func(child): return child is Control and child.visible)


# i0i TabContainer is the horizontal strip that contains tabs
# :C: the dock slot is the first TabContainer above the Inspector.
# :C: found on each press,
# because the Inspector can be dragged to another slot.
func _inspector_slot() -> TabContainer:
	var node: Node = EditorInterface.get_inspector()
	while node != null and not node is TabContainer:
		node = node.get_parent()
	return node as TabContainer
