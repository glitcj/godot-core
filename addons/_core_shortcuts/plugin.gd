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
	_input_dock_toggle(event)




func _input_dock_toggle(event : InputEvent):
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo: return
	# F11
	if key.physical_keycode != KEY_F11: return
	
	# i0i _bottom_dock() returns all nodes relating
	# to all tabs in the bottom dock
	if false: _bottom_dock().visible = !_bottom_dock().visible
	
	
	
	# i0i get_base_control() is a Control node, 
	# specficially, a Panel, it's children are
	# ALL the editor nodes showing on screen.
	
	# i0i setting EditorInterface.get_base_control().visible = false
	# hides all editor nodes.
	if false: # i0i hehe
		EditorInterface.get_base_control().visible = !EditorInterface.get_base_control().visible 

	
	# get_viewport().set_input_as_handled()
	# return

	var bottom_dock := _bottom_dock()
	if bottom_dock == null: return
	# :C: maximising means hiding the area above the bottom dock.
	var area_above_dock := bottom_dock.get_parent().get_child(0) as Control

	# o-o toggle loop through [ show bottom dock > maximise dock > hide dock ]
	if bottom_dock.current_tab == -1:
		bottom_dock.current_tab = maxi(bottom_dock.get_previous_tab(), 0)
	elif area_above_dock.visible:
		area_above_dock.visible = false
	else:
		area_above_dock.visible = true
		hide_bottom_panel()
		_focus_main_screen()

	get_viewport().set_input_as_handled()


# :C: no API says which control is a main screen's work area,
# so the largest visible focusable control is taken.
func _focus_main_screen() -> void:
	var work_area : Control
	for control : Control in EditorInterface.get_editor_main_screen().find_children("*", "Control", true, false):
		if control.focus_mode != Control.FOCUS_ALL or not control.is_visible_in_tree(): continue
		if work_area == null or control.size.x * control.size.y > work_area.size.x * work_area.size.y: work_area = control
	if work_area != null: work_area.grab_focus()


# :C: the bottom dock has no official getter,
# so it is found by its class name.
func _bottom_dock() -> TabContainer:
	var found := EditorInterface.get_base_control().find_children("*", "EditorBottomPanel", true, false)
	return found.front() as TabContainer


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
