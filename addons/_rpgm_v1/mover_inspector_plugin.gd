@tool
# CLAUDE: replaces the two stacked @export_tool_button rows on _RPGM_Mover
# with one HBox row of buttons, placed just above map_position
extends EditorInspectorPlugin


# o- this plugin is called by who ?
func _can_handle(object: Object) -> bool:
	return object is _RPGM_Mover

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if name != "map_position": return false

	var box := HBoxContainer.new()
	box.add_child(_make_button("Quantise via Map", Callable(object, "_quantise_via_map_position")))
	box.add_child(_make_button("Quantise via Global", Callable(object, "_quantise_via_global_position")))
	add_custom_control(box)
	return false

func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	return button
