@tool
# CLAUDE: the Inspector row for a lambda queue: one line per command and a
# button that opens the queue in the RPGM dock.
# LESSON: an EditorProperty reads in _update_property() and writes with
# emit_changed(). This row is read-only, so it never writes.
class_name _RPGM_Plugin_Lambda_Queue_Property
extends EditorProperty

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


# CLAUDE: the lines show only number and class name now, so the row no longer
# listens to history_changed; the Inspector refreshes it when the array changes.
func _update_property() -> void:
	for child in _lines.get_children():
		_lines.remove_child(child)
		child.queue_free()

	var queue = get_edited_object().get(get_edited_property())
	if not queue is Array: return

	if queue.is_empty(): _add_line("No commands")
	for i in queue.size():
		_add_line("%d   %s" % [i + 1, _RPGM_Plugin_Lambda_Text.class_name_of(queue[i])])


func _add_line(text : String) -> void:
	var line := Label.new()
	line.text = text
	line.clip_text = true
	_lines.add_child(line)
