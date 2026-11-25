@tool
# :C: read-only Inspector row for a lambda queue,
# with a button to open the RPGM dock.
class_name _RPGM_Plugin_Lambda_Queue_Property
extends EditorProperty

signal edit_pressed

var _box := VBoxContainer.new()
var _lambda_names := Label.new()
var _edit_button := Button.new()


func _init() -> void:
	_edit_button.text = "Edit in RPGM dock"
	_edit_button.icon = EditorInterface.get_editor_theme().get_icon("Edit", "EditorIcons")
	_edit_button.pressed.connect(edit_pressed.emit)

	_lambda_names.clip_text = true
	_box.add_child(_lambda_names)
	_box.add_child(_edit_button)
	add_child(_box)
	# :C: full width under the label,
	# not squeezed into the right half.
	set_bottom_editor(_box)


# :C: the Inspector calls this when the lambda queue changes.
func _update_property() -> void:
	var lambda_queue : Array = get_edited_object().get(get_edited_property())
	var lines := PackedStringArray()
	for i in lambda_queue.size():
		lines.append("%d   %s" % [i + 1, _RPGM_Plugin_Lambda_Helper.class_name_of(lambda_queue[i])])
	_lambda_names.text = "\n".join(lines) if not lines.is_empty() else "No commands"
