@tool
extends Control
class_name _RPGM_Plugin_Bottom_Dock


# i0 loads the the lambda queue EditorProperty and shows it
# does the same for many editor properties defined in the future.

# i0 the lambda queue "widget" is complicated so needs its own def


# CLAUDE: the dock is now only a router. It follows the editor selection and
# decides what to show for the selected node; the actual UIs live in their
# own scripts (the lambda queue editor) or are a couple of buttons.
# Removed: the RPGM title, the Clicker / Describe Node placeholder buttons,
# the debug prints and the fixed 500px box (see the .tscn — the dock now
# fills the bottom panel).
#
# LESSON: keep a dock thin. "What is selected?" belongs here; "how do I edit
# a lambda queue?" belongs to the widget, so each file answers one question.

signal bottom_dock_requested
signal rpgm_dock_requested
signal output_bottom_dock_requested

var on_selection_interface : VBoxContainer = VBoxContainer.new()
var _queue_editor := _RPGM_Plugin_Lambda_Queue_Editor.new()
var _hint := Label.new()


func _ready() -> void:
	_hint.text = "Select an _RPGM_Script, an _RPGM_Event or a TileMapLayer."
	_hint.modulate.a = 0.55
	%_content.add_child(_hint)
	%_content.add_child(on_selection_interface)

	_queue_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	%_content.add_child(_queue_editor)

	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	_on_selection_changed()


# LESSON: disconnect from editor singletons when leaving, so disabling the
# plugin leaves nothing behind.
func _exit_tree() -> void:
	var selection := EditorInterface.get_selection()
	if selection.selection_changed.is_connected(_on_selection_changed):
		selection.selection_changed.disconnect(_on_selection_changed)


func _log(message):
	print("[_RPGM_Plugin %s] %s" % [self, message] )


# Opens one queue of a script node, e.g. from the Inspector's
# "Edit in RPGM dock" button.
func show_queue(node : Node, property : StringName) -> void:
	_on_rpgm_script_node_selected(node)
	_queue_editor.show_queue(property)


func _on_selection_changed() -> void:
	# i0 clear on selection interface
	for child in on_selection_interface.get_children(): child.queue_free()
	_queue_editor.visible = false
	_hint.visible = true

	var nodes := EditorInterface.get_selection().get_selected_nodes()
	if nodes.size() != 1: return
	var node := nodes[0]

	if node is _RPGM_Node: _on_rpgm_node_selected(node)
	if node is _RPGM_Event: _on_rpgm_event_node_selected(node)
	if node is TileMapLayer: _on_rpgm_tilemap_node_selected(node)
	if node is _RPGM_Script: _on_rpgm_script_node_selected(node)


func _on_rpgm_node_selected(node : _RPGM_Node):
	rpgm_dock_requested.emit()
	var _on_press = func(node : _RPGM_Node):
		print("i0i0")
		# print(node.get_property_list())
		output_bottom_dock_requested.emit()
	_add_button("Describe _RPGM_Node", _on_press.bind(node))


func _add_button(text : String, callback : Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	on_selection_interface.add_child(button)
	_hint.visible = false


func _on_rpgm_event_node_selected(node : _RPGM_Mover):
	_add_button("Quantise via Map", node._quantise_via_map_position)
	_add_button("Quantise via Global", node._quantise_via_global_position)



func _on_rpgm_tilemap_node_selected(node : TileMapLayer):
	_add_button("Describe Tilemap", func(): print(node))
	


# CLAUDE: a script node gets the lambda queue editor, and the dock is raised
func _on_rpgm_script_node_selected(node : _RPGM_Script):
	_hint.visible = false
	_queue_editor.edit(node)
	_queue_editor.visible = true
	bottom_dock_requested.emit()
