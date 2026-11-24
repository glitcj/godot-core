@tool
# CLAUDE: the Inspector row for a lambda queue. Replaces the stock array
# editor (opaque resource slots) with one readable line per command and a
# button that opens the queue in the RPGM dock, where the editing happens.
#
# LESSON: an EditorProperty is one row of the Inspector for one property.
#	read  -> only in _update_property()
#	write -> only with emit_changed(); the Inspector applies it with undo
# This row is read-only, so it never calls emit_changed().
class_name _RPGM_Plugin_Lambda_Queue_Property
extends EditorProperty

# LESSON: signals go up, calls go down. The row does not know the dock
# exists; it only says "edit was pressed" and whoever created it decides.
signal edit_pressed

var _box := VBoxContainer.new()
var _lines := VBoxContainer.new()
var _edit_button := Button.new()


func _init() -> void:
	_edit_button.text = "Edit in RPGM dock"
	_edit_button.icon = EditorInterface.get_editor_theme().get_icon("Edit", "EditorIcons")
	_edit_button.pressed.connect(edit_pressed.emit)

	_box.add_child(_lines)
	_box.add_child(_edit_button)
	add_child(_box)
	# full width under the label instead of squeezed into the right half
	set_bottom_editor(_box)


# The Inspector refreshes a row when the array itself changes, but not when
# a value inside one of its lambdas does — so listen for every edit.
func _enter_tree() -> void:
	EditorInterface.get_editor_undo_redo().history_changed.connect(update_property)


func _exit_tree() -> void:
	EditorInterface.get_editor_undo_redo().history_changed.disconnect(update_property)


func _update_property() -> void:
	for child in _lines.get_children():
		_lines.remove_child(child)
		child.queue_free()

	var object := get_edited_object()
	if object == null: return
	var queue = object.get(get_edited_property())
	if not queue is Array: return

	if queue.is_empty():
		_lines.add_child(_make_line("No commands", true))
	for i in queue.size():
		_lines.add_child(_make_line("%d   %s   %s" % [
			i + 1,
			_RPGM_Plugin_Lambda_Text.friendly_name(queue[i]),
			_RPGM_Plugin_Lambda_Text.summary(queue[i])], false))


func _make_line(text : String, dim : bool) -> Label:
	var line := Label.new()
	line.text = text
	line.clip_text = true
	line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if dim: line.modulate.a = 0.55
	return line
