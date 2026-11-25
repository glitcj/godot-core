@tool
extends Control
class_name _RPGM_Plugin_Bottom_Dock


# i0 loads the the lambda queue EditorProperty and shows it
# does the same for many editor properties defined in the future.

# i0 the lambda queue "widget" is complicated so needs its own def


# CLAUDE: the dock follows the editor selection and decides what to show.

signal bottom_dock_requested
signal output_bottom_dock_requested

var on_selection_interface : VBoxContainer = VBoxContainer.new()
var _lambda_queue_editor := _RPGM_Plugin_Lambda_Queue_Editor.new()
var _hint := Label.new()


func _ready() -> void:
	_hint.text = "Select an _RPGM_Script, an _RPGM_Event or a TileMapLayer."
	_hint.modulate.a = 0.55
	%_content.add_child(_hint)
	%_content.add_child(on_selection_interface)

	_lambda_queue_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	%_content.add_child(_lambda_queue_editor)

	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	_on_selection_changed()


# CLAUDE: disconnect from editor singletons when leaving.
func _exit_tree() -> void:
	var selection := EditorInterface.get_selection()
	if selection.selection_changed.is_connected(_on_selection_changed):
		selection.selection_changed.disconnect(_on_selection_changed)


# CLAUDE: opens one lambda queue of a script node, from the Inspector's "Edit in RPGM dock" button.
func show_lambda_queue(node : Node, lambda_queue_property : StringName) -> void:
	_on_rpgm_script_node_selected(node)
	_lambda_queue_editor.show_lambda_queue(lambda_queue_property)


func _on_selection_changed() -> void:
	# i0 clear on selection interface
	for child in on_selection_interface.get_children(): child.queue_free()
	_lambda_queue_editor.visible = false
	_hint.visible = true

	var nodes := EditorInterface.get_selection().get_selected_nodes()
	if nodes.size() != 1: return
	var node := nodes[0]

	if node is _RPGM_Node: _on_rpgm_node_selected(node)
	if node is _RPGM_Event: _on_rpgm_event_node_selected(node)
	if node is TileMapLayer: _on_rpgm_tilemap_node_selected(node)
	if node is _RPGM_Script: _on_rpgm_script_node_selected(node)


func _on_rpgm_node_selected(_node : _RPGM_Node):
	bottom_dock_requested.emit()
	_add_button("Describe _RPGM_Node", func():
		print("i0i0")
		output_bottom_dock_requested.emit())


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


# CLAUDE: a script node gets the lambda queue editor.
func _on_rpgm_script_node_selected(node : _RPGM_Script):
	_hint.visible = false
	_lambda_queue_editor.edit(node)
	_lambda_queue_editor.visible = true
	bottom_dock_requested.emit()
