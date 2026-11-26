@tool
extends EditorPlugin

func _enter_tree() -> void:
	EditorInterface.get_editor_main_screen().add_child(panel)
	_show_editor_state()

func _exit_tree() -> void:
	panel.queue_free()
	
func _input(event: InputEvent) -> void:
		var key := event as InputEventKey
		if key == null or not key.pressed or key.echo: return

# i0i a main screen tab needs _has_main_screen, _get_plugin_name
# and _make_visible; and the panel needs 
# size_flags_vertical = SIZE_EXPAND_FILL.

func _has_main_screen() -> bool: return true

func _get_plugin_name() -> String: return "Core"

func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("WorldEnvironment", "EditorIcons")

func _make_visible(visible: bool) -> void:
	panel.visible = visible
	
var panel := Panel.new()
var label := Label.new()
var button := Button.new()
func _show_editor_state():
	# :C: tells the main screen's VBoxContainer to give the panel
	# all spare height; containers ignore anchors, so without it height is zero.
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(label)
	panel.add_child(button)
	
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	# label.pivot_offset = label.get_
	label.scale = Vector2.ONE * 5
	label.text = "Core Editor\n"
	label.text += "%s\n" % panel.get_tree_string_pretty()
	
	

func _refresh():
	pass
