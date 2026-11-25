@tool
# CLAUDE: adds a row of Quantise buttons to the _RPGM_Mover inspector.
extends EditorInspectorPlugin


# o- this plugin is called by who ?
# i0 object is passed in by the editor
func _can_handle(object: Object) -> bool:
	return object is _RPGM_Mover


# CLAUDE: called once per object, before any property; adds the row at the top.
func _parse_begin(object: Object) -> void:
	_add_quantise_row(object)


# CLAUDE: adds a second row above "speed"; returning false keeps the stock row.
func _parse_property(object: Object, _type: Variant.Type, name: String, _hint_type: PropertyHint, _hint_string: String, _usage_flags: int, _wide: bool) -> bool:
	if name == "speed": _add_quantise_row(object)
	return false


func _add_quantise_row(object: Object) -> void:
	var box := HBoxContainer.new()
	box.add_child(_make_button("Quantise via Map", Callable(object, "_quantise_via_map_position")))
	box.add_child(_make_button("Quantise via Global", Callable(object, "_quantise_via_global_position")))
	add_custom_control(box)


func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	return button
