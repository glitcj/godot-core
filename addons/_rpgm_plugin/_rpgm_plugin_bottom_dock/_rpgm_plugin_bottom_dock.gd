@tool
extends Control
class_name _RPGM_Plugin_Bottom_Dock


var on_selection_interface := HBoxContainer.new()
func _ready() -> void:
	%_clicker_button.pressed.connect(func(): _log("clicked !"))
	%_describe_node_button.pressed.connect(func(): print("clicked !"))
	%_on_selection_interface_margin_box.add_child(on_selection_interface)
	
	# i0 mover quantisation buttons
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

	# _on_mover_button_selected()
	if node is _RPGM_Mover: _on_mover_button_selected(node)


func _add_button(text : String, callback : Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	on_selection_interface.add_child(button)

func _on_mover_button_selected(node : _RPGM_Mover):
	_add_button("Quantise via Map", node._quantise_via_map_position)
	_add_button("Quantise via Global", node._quantise_via_global_position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
