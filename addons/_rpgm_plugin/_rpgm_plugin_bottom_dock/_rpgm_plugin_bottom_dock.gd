@tool
extends Control
class_name _RPGM_Plugin_Bottom_Dock

signal bottom_dock_requested

var on_selection_interface : VBoxContainer = VBoxContainer.new()

func _ready() -> void:
	
	
	%_clicker_button.pressed.connect(func(): _log("clicked !"))
	%_describe_node_button.pressed.connect(func(): print("clicked !"))
	%_on_selection_interface_margin_box.add_child(on_selection_interface)
	
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	_on_selection_changed()
	
func _log(message):
	print("[_RPGM_Plugin %s] %s" % [self, message] )

func _on_selection_changed() -> void:
	print(EditorInterface.get_selection().get_selected_nodes())
	
	# i0 clear on selection interface
	for child in on_selection_interface.get_children(): child.queue_free()

	var nodes := EditorInterface.get_selection().get_selected_nodes()
	if nodes.size() != 1: return
	var node := nodes[0]

	if node is _RPGM_Event: _on_rpgm_event_node_selected(node)
	if node is TileMapLayer: _on_rpgm_tilemap_node_selected(node)
	if node is _RPGM_Script: _on_rpgm_script_node_selected(node)


func _add_button(text : String, callback : Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	on_selection_interface.add_child(button)

func _on_rpgm_event_node_selected(node : _RPGM_Mover):
	_add_button("Quantise via Map", node._quantise_via_map_position)
	_add_button("Quantise via Global", node._quantise_via_global_position)

func _on_rpgm_tilemap_node_selected(node : TileMapLayer):
	_add_button("Describe Tilemap", func(): print(node))

# CLAUDE: parameter was typed TileMapLayer, which rejects an _RPGM_Script
func _on_rpgm_script_node_selected(node : _RPGM_Script):
	# on_selection_interface.size = Vector2(0, 0)
	on_selection_interface.custom_maximum_size = Vector2(500, 0)
	bottom_dock_requested.emit()
	# _add_button("Describe Script", func(): print(node))
	_add_property_editor(node, &"on_action", "On Action")

# CLAUDE: shows one of the selected node's properties in the dock using the
# same widget the Inspector uses (for on_action: the lambda list with its
# "Add Element" button). The widget only reports edits, so they are applied
# here through the editor's undo system, which also marks the scene unsaved.
func _add_property_editor(node : Object, property : StringName, label : String) -> void:
	print_tree_pretty()
	print(node.get_property_list())
	
	for p in node.get_property_list():

		if p.name != property: continue

		var editor := EditorInspector.instantiate_property_editor(
			node, p.type, p.name, p.hint, p.hint_string, p.usage
			)
		editor.set_object_and_property(node, p.name)
		editor.label = label
		editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		editor.property_changed.connect(
			func(changed : StringName, value : Variant, _field : StringName, _changing : bool):
				var undo := EditorInterface.get_editor_undo_redo()
				undo.create_action("Set %s" % changed)
				undo.add_do_property(node, changed, value)
				undo.add_undo_property(node, changed, node.get(changed))
				undo.commit_action()
				editor.update_property())

		on_selection_interface.add_child(editor)
		editor.update_property()
		return
