@tool
# CLAUDE: Inspector plugin for _RPGM_Script. Swaps the stock array editor of
# every lambda queue for the readable _RPGM_Plugin_Lambda_Queue_Property row.
#
# LESSON: an EditorInspectorPlugin does not draw anything itself. The editor
# asks it two questions while building the Inspector:
#	_can_handle(object)     "is this object yours?"
#	_parse_property(...)    "do you want to replace this property's row?"
# Return true from _parse_property to remove the stock row, false to keep it.
#
# LESSON: one inspector plugin per kind of object keeps each one tiny
# (movers are handled next door in _rpgm_plugin_inspector.gd).
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
