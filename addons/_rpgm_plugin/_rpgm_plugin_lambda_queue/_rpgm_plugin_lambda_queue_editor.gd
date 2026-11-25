@tool
# :C: the lambda queue editor in the RPGM dock;
# every edit is an undo action,
# and every redraw comes from history_changed.
class_name _RPGM_Plugin_Lambda_Queue_Editor
extends VBoxContainer

var _node : Node
var _lambda_queue_property : StringName # i0 eg on action, on frame ?
var _selected_index := -1

var _listed_lambda_count := -1
var _shown_lambda : Resource
var _value_editors : Array[EditorProperty] = []

var _tabs := TabBar.new()
var _add_button := MenuButton.new()
var _duplicate_button : Button
var _up_button : Button
var _down_button : Button
var _delete_button : Button
var _lambda_list := Tree.new()
var _lambda_values := VBoxContainer.new()
var _lambda_values_dialog := AcceptDialog.new()


func _init() -> void:
	_build_layout()


func _enter_tree() -> void:
	EditorInterface.get_editor_undo_redo().history_changed.connect(_refresh)


func _exit_tree() -> void:
	EditorInterface.get_editor_undo_redo().history_changed.disconnect(_refresh)


# i0 called from bottom dock control node
# io edit gets one tab per lambda queue
# :C: start editing this node's lambda queues, on the first tab.
func edit(node : Node) -> void:
	_node = node
	_tabs.current_tab = 0
	_on_tab_changed(0)


# :C: switch to one lambda queue of the node, e.g. &"on_frame".
func show_lambda_queue(lambda_queue_property : StringName) -> void:
	_tabs.current_tab = _RPGM_Plugin_Lambda_Helper.LAMBDA_QUEUE_PROPERTIES.find(lambda_queue_property)


# i0 these getters read the "queue property"
# which is the lambda queue
# i0 get currently selected lambda queue ?
# :C: always read from the node with get(),
# because _RPGM_Script is a placeholder in the editor.
func _get_lambda_queue() -> Array:
	return _node.get(_lambda_queue_property)


func _get_selected_lambda() -> Resource:
	return _get_lambda_queue()[_selected_index] if _selected_index >= 0 else null


# :C: the only place the panes are redrawn from the data.
func _refresh() -> void:
	if not is_instance_valid(_node): return
	_selected_index = clampi(_selected_index, -1, _get_lambda_queue().size() - 1)
	_refresh_tabs()
	_refresh_toolbar()
	_refresh_lambda_list()
	_refresh_lambda_values()


func _refresh_tabs() -> void:
	var properties := _RPGM_Plugin_Lambda_Helper.LAMBDA_QUEUE_PROPERTIES
	for tab in properties.size():
		_tabs.set_tab_title(tab, "%s  %d" % [properties[tab], _node.get(properties[tab]).size()])


func _refresh_toolbar() -> void:
	var has_selection := _selected_index >= 0
	_duplicate_button.disabled = not has_selection
	_delete_button.disabled = not has_selection
	_up_button.disabled = _selected_index <= 0
	_down_button.disabled = not has_selection or _selected_index >= _get_lambda_queue().size() - 1


# :C: rows are rebuilt only when their number changes,
# so the list keeps its scroll position.
func _refresh_lambda_list() -> void:
	var lambda_queue := _get_lambda_queue()
	_lambda_list.set_block_signals(true)

	if lambda_queue.size() != _listed_lambda_count:
		_listed_lambda_count = lambda_queue.size()
		_lambda_list.clear()
		var root := _lambda_list.create_item()
		for i in lambda_queue.size(): _lambda_list.create_item(root)

	var rows := _lambda_list.get_root().get_children()
	for i in lambda_queue.size():
		rows[i].set_text(0, str(i + 1))
		rows[i].set_text(1, _RPGM_Plugin_Lambda_Helper.class_name_of(lambda_queue[i]))

	if _selected_index >= 0: rows[_selected_index].select(0)
	else: _lambda_list.deselect_all()
	_lambda_list.set_block_signals(false)


# :C: value editors are rebuilt only for a different lambda,
# so focus stays in the field being typed in.
func _refresh_lambda_values() -> void:
	var lambda := _get_selected_lambda()
	if lambda != _shown_lambda:
		_rebuild_lambda_values(lambda)
		return
	for editor in _value_editors: editor.update_property()


func _rebuild_lambda_values(lambda : Resource) -> void:
	_shown_lambda = lambda
	_value_editors.clear()
	for child in _lambda_values.get_children():
		_lambda_values.remove_child(child)
		child.queue_free()
	_lambda_values_dialog.title = _RPGM_Plugin_Lambda_Helper.class_name_of(lambda)
	if lambda == null:
		_lambda_values_dialog.hide()
		return

	# :C: reuse the Inspector's own widget per value;
	# it only reports the edit, _commit_value applies it.
	for p in _RPGM_Plugin_Lambda_Helper.exported_properties(lambda):
		var editor := EditorInspector.instantiate_property_editor(
			lambda, p.type, p.name, p.hint, p.hint_string, p.usage)
		if editor == null: continue
		editor.set_object_and_property(lambda, p.name)
		editor.label = p.name
		editor.name_split_ratio = 0.3
		editor.property_changed.connect(_commit_value.bind(lambda))
		_lambda_values.add_child(editor)
		editor.update_property()
		_value_editors.append(editor)


# :C: undo gets a changed copy of the array;
# editing the live one makes "before" and "after" the same.
func _commit_lambda_queue(action_name : String, lambda_queue : Array) -> void:
	var undo := EditorInterface.get_editor_undo_redo()
	undo.create_action(action_name)
	undo.add_do_property(_node, _lambda_queue_property, lambda_queue)
	undo.add_undo_property(_node, _lambda_queue_property, _get_lambda_queue())
	undo.commit_action()


# :C: _node is the action's context, so the edit
# lands in the scene's history and marks it unsaved.
func _commit_value(
		property : StringName, value : Variant, _field : StringName,
		changing : bool, lambda : Resource) -> void:
	var undo := EditorInterface.get_editor_undo_redo()
	# :C: while a slider is dragged,
	# the stream of edits merges into one undo step.
	var merge := UndoRedo.MERGE_ENDS if changing else UndoRedo.MERGE_DISABLE
	undo.create_action("Set Value", merge, _node)
	undo.add_do_property(lambda, property, value)
	undo.add_undo_property(lambda, property, lambda.get(property))
	undo.commit_action()


func _on_tab_changed(tab : int) -> void:
	_lambda_queue_property = _RPGM_Plugin_Lambda_Helper.LAMBDA_QUEUE_PROPERTIES[tab]
	_selected_index = 0
	_listed_lambda_count = -1
	_refresh()


func _on_row_selected() -> void:
	_selected_index = _lambda_list.get_selected().get_index()
	_refresh_toolbar()
	_refresh_lambda_values()


# :C: a new lambda goes right after
# the selected one, or at the end.
func _on_add_chosen(menu_index : int) -> void:
	var script_path : String = _add_button.get_popup().get_item_metadata(menu_index)
	var lambda_queue := _get_lambda_queue().duplicate()
	_selected_index += 1
	lambda_queue.insert(_selected_index, _RPGM_Plugin_Lambda_Helper.new_lambda(script_path))
	_commit_lambda_queue("Add Command", lambda_queue)


func _on_duplicate_pressed() -> void:
	var lambda_queue := _get_lambda_queue().duplicate()
	lambda_queue.insert(_selected_index + 1, _get_selected_lambda().duplicate(true))
	_selected_index += 1
	_commit_lambda_queue("Duplicate Command", lambda_queue)


func _on_move_pressed(direction : int) -> void:
	var lambda_queue := _get_lambda_queue().duplicate()
	var to := _selected_index + direction
	var moved = lambda_queue[_selected_index]
	lambda_queue[_selected_index] = lambda_queue[to]
	lambda_queue[to] = moved
	_selected_index = to
	_commit_lambda_queue("Move Command", lambda_queue)


func _on_delete_pressed() -> void:
	var lambda_queue := _get_lambda_queue().duplicate()
	lambda_queue.remove_at(_selected_index)
	_commit_lambda_queue("Delete Command", lambda_queue)


func _fill_add_menu() -> void:
	var popup := _add_button.get_popup()
	popup.clear()
	for lambda_class in _RPGM_Plugin_Lambda_Helper.lambda_classes():
		popup.add_item(lambda_class["class"])
		popup.set_item_metadata(popup.item_count - 1, lambda_class["path"])


# :C: built once; nothing in here reads the node.
func _build_layout() -> void:
	for property in _RPGM_Plugin_Lambda_Helper.LAMBDA_QUEUE_PROPERTIES: _tabs.add_tab("")
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
	# :C: the Mac "delete" key is Backspace.
	_delete_button = _make_tool_button(toolbar, "Remove", "Delete", KEY_BACKSPACE, false)
	_delete_button.pressed.connect(_on_delete_pressed)

	# :C: two columns, number and class name.
	_lambda_list.columns = 2
	_lambda_list.hide_root = true
	_lambda_list.select_mode = Tree.SELECT_ROW
	# :C: search-as-you-type would eat the shortcut keys.
	_lambda_list.allow_search = false
	_lambda_list.set_column_expand(0, false)
	_lambda_list.set_column_custom_minimum_width(0, int(40 * _scale()))
	_lambda_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lambda_list.item_selected.connect(_on_row_selected)
	# :C: double-click or Enter on a row
	# opens its values in a popup.
	_lambda_list.item_activated.connect(func():
		_lambda_values_dialog.popup_centered(Vector2i(int(500 * _scale()), 0)))
	add_child(_lambda_list)

	_lambda_values_dialog.add_child(_lambda_values)
	add_child(_lambda_values_dialog)


# :C: sizes are multiplied by the editor scale,
# so the UI fits hiDPI screens.
func _scale() -> float:
	return EditorInterface.get_editor_scale()


# :C: icons come from the editor theme,
# so they match light and dark themes.
func _icon(icon_name : String) -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon(icon_name, "EditorIcons")


# :C: Button.shortcut with shortcut_context fires only
# while the list has focus and the button is enabled.
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
	button.shortcut_context = _lambda_list
	toolbar.add_child(button)
	return button
