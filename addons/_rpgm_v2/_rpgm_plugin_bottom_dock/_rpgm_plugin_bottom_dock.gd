@tool
extends Control
class_name _RPGM_Plugin_Bottom_Dock

# CLAUDE: row of buttons that follows the editor selection — rebuilt on every
# selection_changed, shown only while a single _RPGM_Mover is selected
var button_row := HBoxContainer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%Button2.button_down.connect(func(): print("clicked !"))




	%Button2.get_parent().add_child(button_row)
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	_on_selection_changed()
	
func _on_selection_changed() -> void:
	for child in button_row.get_children(): child.queue_free()

	var nodes := EditorInterface.get_selection().get_selected_nodes()
	if nodes.size() != 1: return
	var node := nodes[0]

	if node is _RPGM_Mover:
		_add_button("Quantise via Map", node._quantise_via_map_position)
		_add_button("Quantise via Global", node._quantise_via_global_position)

func _add_button(text : String, callback : Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	button_row.add_child(button)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
