@tool
# :C: the lambda queue editor in the RPGM dock;
# its layout is the .tscn next to this script.
# :C: every edit is an undo action,
# and every redraw comes from history_changed.
class_name _RPGM_Plugin_Lambda_Queue_Editor
extends VBoxContainer # Control and not EditorProperty !

var _node : Node # i0 selected node from the scene tree
var _lambda_queue_property : StringName # i0 eg on action, on frame
var _selected_index := -1 # i0 highlighted lambda index in the bottom dock

# i0 this is the EditorInspector node included
# in the pop up dialogue, after clicking a lambda
var _lambda_inspector := EditorInspector.new()


# :C: wires up what the scene cannot hold.
func _ready() -> void:
	for property in _RPGM_Plugin_Lambda_Helper.LAMBDA_QUEUE_PROPERTIES: %Tabs.add_tab("")
	%Tabs.tab_changed.connect(_on_tab_changed)
	%LambdaList.item_selected.connect(_on_row_selected)
	%LambdaList.item_activated.connect(_on_row_activated)
	%LambdaInspectorDialog.add_child(_lambda_inspector)

	# :C: the editor's own Create dialog, limited to _RPGM_Lambda classes.
	%Add.pressed.connect(EditorInterface.popup_create_dialog.bind(
		_on_add_chosen, &"_RPGM_Lambda", "", "Add Command"))
	%Duplicate.pressed.connect(_on_duplicate_pressed)
	%MoveUp.pressed.connect(_on_move_pressed.bind(-1))
	%MoveDown.pressed.connect(_on_move_pressed.bind(1))
	%Remove.pressed.connect(_on_delete_pressed)

	# :C: each toolbar button is named after its editor icon.
	# :C: shortcut_context limits a shortcut to when the list has focus.
	for button : Button in %Toolbar.get_children():
		button.icon = EditorInterface.get_editor_theme().get_icon(button.name, "EditorIcons")
		button.shortcut_context = %LambdaList

	# :C: no disconnect needed;
	# Godot drops the connection when this node is freed.
	EditorInterface.get_editor_undo_redo().history_changed.connect(_refresh)


# i0 called from bottom dock control node
# :C: start editing this node's lambda queues, on the first tab.
func edit(node : Node) -> void:
	_node = node
	%Tabs.current_tab = 0
	_on_tab_changed(0)


# :C: switch to one lambda queue of the node, e.g. &"on_frame".
func show_lambda_queue(lambda_queue_property : StringName) -> void:
	%Tabs.current_tab = _RPGM_Plugin_Lambda_Helper.LAMBDA_QUEUE_PROPERTIES.find(lambda_queue_property)


# i0 these getters read the "queue property"
# which is the lambda queue
# i0 get currently selected lambda queue ?
# :C: always read from the node with get(),
# because _RPGM_Script is a placeholder in the editor.
func _get_lambda_queue() -> Array:
	return _node.get(_lambda_queue_property)


# :C: the only place the panes are redrawn from the data.
func _refresh() -> void:
	if not is_instance_valid(_node): return
	_selected_index = clampi(_selected_index, -1, _get_lambda_queue().size() - 1)
	_refresh_tabs()
	_refresh_toolbar()
	_refresh_lambda_list()


func _refresh_tabs() -> void:
	var properties := _RPGM_Plugin_Lambda_Helper.LAMBDA_QUEUE_PROPERTIES
	for tab in properties.size():
		%Tabs.set_tab_title(tab, "%s  %d" % [properties[tab], _node.get(properties[tab]).size()])


func _refresh_toolbar() -> void:
	var has_selection := _selected_index >= 0
	%Duplicate.disabled = not has_selection
	%Remove.disabled = not has_selection
	%MoveUp.disabled = _selected_index <= 0
	%MoveDown.disabled = not has_selection or _selected_index >= _get_lambda_queue().size() - 1


# :C: select() does not emit item_selected, so no signal blocking.
func _refresh_lambda_list() -> void:
	var lambda_queue := _get_lambda_queue()
	%LambdaList.clear()
	for i in lambda_queue.size():
		%LambdaList.add_item("%d   %s" % [i + 1, _RPGM_Plugin_Lambda_Helper.class_name_of(lambda_queue[i])])
	if _selected_index >= 0: %LambdaList.select(_selected_index)


# :C: undo gets a changed copy of the array;
# editing the live one makes "before" and "after" the same.
func _commit_lambda_queue(action_name : String, lambda_queue : Array) -> void:
	var undo := EditorInterface.get_editor_undo_redo()
	undo.create_action(action_name)
	undo.add_do_property(_node, _lambda_queue_property, lambda_queue)
	undo.add_undo_property(_node, _lambda_queue_property, _get_lambda_queue())
	undo.commit_action()


func _on_tab_changed(tab : int) -> void:
	_lambda_queue_property = _RPGM_Plugin_Lambda_Helper.LAMBDA_QUEUE_PROPERTIES[tab]
	_selected_index = 0
	_refresh()


func _on_row_selected(index : int) -> void:
	_selected_index = index
	_refresh_toolbar()


# :C: double-click or Enter on a row opens its values
# in a popup holding a real Inspector,
# which records its own undo steps.
func _on_row_activated(index : int) -> void:
	var lambda : Resource = _get_lambda_queue()[index]
	_lambda_inspector.edit(lambda)
	%LambdaInspectorDialog.title = _RPGM_Plugin_Lambda_Helper.class_name_of(lambda)
	# :C: sizes are multiplied by the editor scale for hiDPI screens.
	%LambdaInspectorDialog.popup_centered(Vector2i(Vector2(500, 400) * EditorInterface.get_editor_scale()))


# :C: the Create dialog passes the chosen class's script path,
# or "" when cancelled.
# :C: the new lambda goes after the selected one.
func _on_add_chosen(script_path : String) -> void:
	if script_path.is_empty(): return
	var lambda_queue := _get_lambda_queue().duplicate()
	_selected_index += 1
	lambda_queue.insert(_selected_index, _RPGM_Plugin_Lambda_Helper.new_lambda(script_path))
	_commit_lambda_queue("Add Command", lambda_queue)


func _on_duplicate_pressed() -> void:
	var lambda_queue := _get_lambda_queue().duplicate()
	lambda_queue.insert(_selected_index + 1, lambda_queue[_selected_index].duplicate(true))
	_selected_index += 1
	_commit_lambda_queue("Duplicate Command", lambda_queue)


func _on_move_pressed(direction : int) -> void:
	var lambda_queue := _get_lambda_queue().duplicate()
	var to := _selected_index + direction
	lambda_queue.insert(to, lambda_queue.pop_at(_selected_index))
	_selected_index = to
	_commit_lambda_queue("Move Command", lambda_queue)


func _on_delete_pressed() -> void:
	var lambda_queue := _get_lambda_queue().duplicate()
	lambda_queue.remove_at(_selected_index)
	_commit_lambda_queue("Delete Command", lambda_queue)
