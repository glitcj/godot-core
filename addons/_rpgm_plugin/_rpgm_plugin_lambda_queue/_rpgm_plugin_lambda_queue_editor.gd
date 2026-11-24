@tool
# CLAUDE: the lambda queue editor shown in the RPGM bottom dock: one tab per
# queue, a toolbar, the list of commands, and a popup for a command's values.
# LESSON: a view never changes itself. Every edit is an undo action
# (_commit_queue / _commit_value) and every redraw comes from history_changed.
class_name _RPGM_Plugin_Lambda_Queue_Editor
extends VBoxContainer

# what is being edited
var _node : Node
var _queue_properties : Array[StringName] = []
var _queue_property : StringName # i0 eg on action, on frame ?
var _selected_index := -1

# what the two panes currently show
var _listed_count := -1
var _shown_lambda : Resource
var _value_editors : Array[EditorProperty] = []

# controls
var _tabs := TabBar.new()
var _add_button := MenuButton.new()
var _duplicate_button : Button
var _up_button : Button
var _down_button : Button
var _delete_button : Button
var _list := Tree.new()
var _values := VBoxContainer.new()
var _values_dialog := AcceptDialog.new()


func _init() -> void:
	_build_layout()


func _enter_tree() -> void:
	EditorInterface.get_editor_undo_redo().history_changed.connect(_refresh)


func _exit_tree() -> void:
	EditorInterface.get_editor_undo_redo().history_changed.disconnect(_refresh)


# Start editing the lambda queues of this node.
# i0 called from bottom dock control node


# io edit gets one tab per lambda queue
func edit(node : Node) -> void:
	_node = node
	_queue_properties = _RPGM_Plugin_Lambda_Text.queue_properties(node)
	_queue_property = _queue_properties[0] if not _queue_properties.is_empty() else &""
	_selected_index = _first_index()

	_tabs.set_block_signals(true)
	_tabs.clear_tabs()
	for property in _queue_properties: _tabs.add_tab("")
	_tabs.set_block_signals(false)

	_listed_count = -1
	_rebuild_values(null)
	_refresh()


# Switch to one of the node's queues, e.g. &"on_frame".
func show_queue(property : StringName) -> void:
	var tab := _queue_properties.find(property)
	if tab >= 0: _tabs.current_tab = tab


# ---- reading


# Chunk 3 of 7, lines 70-83: two small readers that everything else uses; they always fetch the queue fresh from the node, so the editor never holds its own copy of the data. Clear?
# i0 these getters read the "queue property" 
# which is the lambda queue
# i0 get currently selected lambda queue ?
func _get_queue() -> Array:
	if not is_instance_valid(_node) or _queue_property.is_empty(): return []
	var queue = _node.get(_queue_property)
	return queue if queue is Array else []


func _first_index() -> int:
	return 0 if not _get_queue().is_empty() else -1


func _get_selected_lambda() -> Resource:
	var queue := _get_queue()
	if _selected_index < 0 or _selected_index >= queue.size(): return null
	return queue[_selected_index] as Resource


# The only place the panes are redrawn from the data.
func _refresh() -> void:
	if not is_instance_valid(_node): return
	_selected_index = clampi(_selected_index, -1, _get_queue().size() - 1)
	_refresh_tabs()
	_refresh_toolbar()
	_refresh_list()
	_refresh_values()


func _refresh_tabs() -> void:
	for tab in _queue_properties.size():
		var property := _queue_properties[tab]
		var count := (_node.get(property) as Array).size()
		_tabs.set_tab_title(tab, "%s  %d" % [property, count])


func _refresh_toolbar() -> void:
	var count := _get_queue().size()
	var has_selection := _selected_index >= 0
	_add_button.disabled = _queue_property.is_empty()
	_duplicate_button.disabled = not has_selection
	_delete_button.disabled = not has_selection
	_up_button.disabled = _selected_index <= 0
	_down_button.disabled = not has_selection or _selected_index >= count - 1


# Rows are rebuilt only when their number changes, so the list keeps its
# scroll position; otherwise the texts are updated in place.
func _refresh_list() -> void:
	var queue := _get_queue()
	_list.set_block_signals(true)

	if queue.size() != _listed_count:
		_listed_count = queue.size()
		_list.clear()
		var root := _list.create_item()
		for i in queue.size(): _list.create_item(root)

	# CLAUDE: two columns now, number and raw class name (no value summary)
	var rows := _list.get_root().get_children()
	for i in queue.size():
		rows[i].set_text(0, str(i + 1))
		rows[i].set_text(1, _RPGM_Plugin_Lambda_Text.class_name_of(queue[i]))

	if _selected_index >= 0: rows[_selected_index].select(0)
	else: _list.deselect_all()
	_list.set_block_signals(false)


# The value editors are rebuilt only when a different lambda is selected, so
# keyboard focus stays in the field being typed in.
func _refresh_values() -> void:
	var lambda := _get_selected_lambda()
	if lambda != _shown_lambda:
		_rebuild_values(lambda)
		return
	for editor in _value_editors: editor.update_property()


func _rebuild_values(lambda : Resource) -> void:
	_shown_lambda = lambda
	_value_editors.clear()
	for child in _values.get_children():
		_values.remove_child(child)
		child.queue_free()
	# CLAUDE: the dialog's title bar replaces the title label and separator
	_values_dialog.title = _RPGM_Plugin_Lambda_Text.class_name_of(lambda)
	if lambda == null:
		_values_dialog.hide()
		return

	# LESSON: reuse the Inspector's own widget for each value instead of
	# writing a text box per type. It only reports the edit; we commit it.
	for p in _RPGM_Plugin_Lambda_Text.exported_properties(lambda):
		var editor := EditorInspector.instantiate_property_editor(
			lambda, p.type, p.name, p.hint, p.hint_string, p.usage)
		if editor == null: continue
		editor.set_object_and_property(lambda, p.name)
		editor.label = p.name
		editor.name_split_ratio = 0.3
		# CLAUDE: connected straight to _commit_value, no forwarding handler
		editor.property_changed.connect(_commit_value.bind(lambda))
		_values.add_child(editor)
		editor.update_property()
		_value_editors.append(editor)


# ---- writing: the only two functions that change data

# LESSON: hand undo a copy of the array. If the live array were changed in
# place, "before" and "after" would be the same object and undo would do nothing.
func _commit_queue(action_name : String, queue : Array) -> void:
	var undo := EditorInterface.get_editor_undo_redo()
	undo.create_action(action_name)
	undo.add_do_property(_node, _queue_property, queue)
	undo.add_undo_property(_node, _queue_property, _get_queue())
	undo.commit_action()


# LESSON: _node is passed as the action's context so the edit lands in the
# scene's history and marks the scene unsaved.
func _commit_value(
		property : StringName, value : Variant, _field : StringName,
		changing : bool, lambda : Resource) -> void:
	var undo := EditorInterface.get_editor_undo_redo()
	# while a slider is dragged, merge the stream of edits into one undo step
	var merge := UndoRedo.MERGE_ENDS if changing else UndoRedo.MERGE_DISABLE
	undo.create_action("Set Value", merge, _node)
	undo.add_do_property(lambda, property, value)
	undo.add_undo_property(lambda, property, lambda.get(property))
	undo.commit_action()


# ---- user actions

func _on_tab_changed(tab : int) -> void:
	if tab < 0 or tab >= _queue_properties.size(): return
	_queue_property = _queue_properties[tab]
	_selected_index = _first_index()
	_listed_count = -1
	_refresh()


func _on_row_selected() -> void:
	_selected_index = _list.get_selected().get_index()
	_refresh_toolbar()
	_refresh_values()


# New commands go right after the selected one, or at the end.
func _on_add_chosen(menu_index : int) -> void:
	var path : String = _add_button.get_popup().get_item_metadata(menu_index)
	var queue := _get_queue().duplicate()
	var at := _selected_index + 1 if _selected_index >= 0 else queue.size()
	queue.insert(at, _RPGM_Plugin_Lambda_Text.new_lambda(path))
	_selected_index = at
	_commit_queue("Add Command", queue)


func _on_duplicate_pressed() -> void:
	var lambda := _get_selected_lambda()
	if lambda == null: return
	var queue := _get_queue().duplicate()
	queue.insert(_selected_index + 1, lambda.duplicate(true))
	_selected_index += 1
	_commit_queue("Duplicate Command", queue)


func _on_move_pressed(direction : int) -> void:
	var queue := _get_queue().duplicate()
	var to := _selected_index + direction
	if _selected_index < 0 or to < 0 or to >= queue.size(): return
	var moved = queue[_selected_index]
	queue[_selected_index] = queue[to]
	queue[to] = moved
	_selected_index = to
	_commit_queue("Move Command", queue)


func _on_delete_pressed() -> void:
	var queue := _get_queue().duplicate()
	if _selected_index < 0 or _selected_index >= queue.size(): return
	queue.remove_at(_selected_index)
	_selected_index = mini(_selected_index, queue.size() - 1)
	_commit_queue("Delete Command", queue)


func _fill_add_menu() -> void:
	var popup := _add_button.get_popup()
	popup.clear()
	for lambda_class in _RPGM_Plugin_Lambda_Text.lambda_classes():
		popup.add_item(lambda_class["class"])
		popup.set_item_metadata(popup.item_count - 1, lambda_class["path"])


# ---- layout: built once; nothing in here reads the node

func _build_layout() -> void:
	_tabs.tab_changed.connect(_on_tab_changed)
	add_child(_tabs)

	var toolbar := HBoxContainer.new()
	add_child(toolbar)

	_add_button.text = "Add"
	_add_button.icon = _icon("Add")
	_add_button.flat = false
	_add_button.tooltip_text = "Add a command after the selected one"
	_add_button.about_to_popup.connect(_fill_add_menu)
	_add_button.get_popup().index_pressed.connect(_on_add_chosen)
	toolbar.add_child(_add_button)

	_duplicate_button = _make_tool_button(toolbar, "Duplicate", "Duplicate", KEY_D, true)
	_duplicate_button.pressed.connect(_on_duplicate_pressed)
	_up_button = _make_tool_button(toolbar, "MoveUp", "Move up", KEY_UP, true)
	_up_button.pressed.connect(_on_move_pressed.bind(-1))
	_down_button = _make_tool_button(toolbar, "MoveDown", "Move down", KEY_DOWN, true)
	_down_button.pressed.connect(_on_move_pressed.bind(1))
	# the Mac "delete" key is Backspace
	_delete_button = _make_tool_button(toolbar, "Remove", "Delete", KEY_BACKSPACE, false)
	_delete_button.pressed.connect(_on_delete_pressed)

	# the list: number | class name
	_list.columns = 2
	_list.hide_root = true
	_list.select_mode = Tree.SELECT_ROW
	# typing in the list would otherwise search it and eat the shortcut keys
	_list.allow_search = false
	_list.set_column_expand(0, false)
	_list.set_column_custom_minimum_width(0, int(40 * _scale()))
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_row_selected)
	# CLAUDE: double-click (or Enter) on a command opens its values in a popup,
	# instead of a pane that is always open beside the list
	_list.item_activated.connect(func():
		_values_dialog.popup_centered(Vector2i(int(500 * _scale()), 0)))
	add_child(_list)

	_values_dialog.add_child(_values)
	add_child(_values_dialog)


# LESSON: take icons from the editor theme and multiply sizes by the editor
# scale, so the UI matches light / dark themes and hiDPI screens.
func _scale() -> float:
	return EditorInterface.get_editor_scale()


func _icon(icon_name : String) -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon(icon_name, "EditorIcons")


# CLAUDE: the key is a native Button.shortcut instead of a gui_input handler.
# LESSON: shortcut_context limits it to when the list has focus, the button
# ignores it while disabled, and the tooltip shows the key by itself.
func _make_tool_button(
		toolbar : Control, icon_name : String, tooltip : String,
		keycode : Key, alt : bool) -> Button:
	var key := InputEventKey.new()
	key.keycode = keycode
	key.alt_pressed = alt

	var button := Button.new()
	button.icon = _icon(icon_name)
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.shortcut = Shortcut.new()
	button.shortcut.events = [key]
	button.shortcut_context = _list
	toolbar.add_child(button)
	return button
