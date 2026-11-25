@tool
# CLAUDE: read-only Inspector row for a lambda queue, with a button that opens it in the RPGM dock.
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
	# CLAUDE: full width under the label instead of squeezed into the right half.
	set_bottom_editor(_box)


# CLAUDE: the Inspector calls this whenever the lambda queue changes.
func _update_property() -> void:
	for child in _lines.get_children():
		_lines.remove_child(child)
		child.queue_free()

	var lambda_queue : Array = get_edited_object().get(get_edited_property())
	if lambda_queue.is_empty(): _add_line("No commands")
	for i in lambda_queue.size():
		_add_line("%d   %s" % [i + 1, _RPGM_Plugin_Lambda_Inspector.class_name_of(lambda_queue[i])])


func _add_line(text : String) -> void:
	var line := Label.new()
	line.text = text
	line.clip_text = true
	_lines.add_child(line)
