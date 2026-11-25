@tool
# :C: swaps the stock array row of each lambda
# queue on _RPGM_Script for a readable one.
extends EditorInspectorPlugin

signal edit_requested(node : Node, lambda_queue_property : StringName)


# :C: the editor asks this first, "is this object yours?".
func _can_handle(object : Object) -> bool:
	return object is _RPGM_Script


# :C: called once per property; returning true replaces the stock row.
func _parse_property(
		object : Object, _type : Variant.Type, name : String,
		_hint_type : PropertyHint, _hint_string : String,
		_usage_flags : int, _wide : bool) -> bool:
	if not StringName(name) in _RPGM_Plugin_Lambda_Helper.LAMBDA_QUEUE_PROPERTIES: return false

	var row := _RPGM_Plugin_Lambda_Queue_Property.new()
	row.edit_pressed.connect(func(): edit_requested.emit(object, StringName(name)))
	add_property_editor(name, row)
	return true
