@tool
# CLAUDE: Inspector plugin for _RPGM_Script. Swaps the stock array editor of
# every lambda queue for the _RPGM_Plugin_Lambda_Queue_Property row.
# LESSON: the editor asks _can_handle "is this object yours?", then
# _parse_property per property; return true to replace the stock row.
extends EditorInspectorPlugin

# Emitted when a queue's "Edit in RPGM dock" button is pressed.
signal edit_requested(node : Node, property : StringName)


func _can_handle(object : Object) -> bool:
	return object is _RPGM_Script


func _parse_property(
		object : Object, type : Variant.Type, name : String,
		_hint_type : PropertyHint, _hint_string : String,
		_usage_flags : int, _wide : bool) -> bool:
	if type != TYPE_ARRAY: return false
	if not _RPGM_Plugin_Lambda_Text.is_lambda_queue(object.get(name)): return false

	var row := _RPGM_Plugin_Lambda_Queue_Property.new()
	row.edit_pressed.connect(func(): edit_requested.emit(object, StringName(name)))
	add_property_editor(name, row)
	return true
