@tool
extends EditorScript

# i0i this editor script will be used
# to learn how to make nodes on the go

var rectangle_timeout := 5.

func _run() -> void:
	print(EditorInterface.get_base_control())
	# :C: get_viewport() belongs to Node; an EditorScript is
	# a RefCounted, never in the scene tree.
	# :C: EditorInterface.get_base_control().get_viewport() gives the editor's main window.
	# print(get_viewport(), EditorInterface.get_base_control())
	# :C: an EditorPlugin (plugin.gd) is a child of EditorNode,
	# next to the base control, not under it.
	# :C: the controls a plugin adds live under the base control.
	# i0i get_viewport works in EditorPlugin plugin.gd because
	# it lives in the tree.
	#
	# root (Window)
	# └── EditorNode
	#     ├── base control (Panel)   <- EditorInterface.get_base_control()
	#     │   └── every visible editor control, incl. a plugin's docks
	#     ├── plugin.gd (EditorPlugin)   <- _core_shortcuts
	#     └── plugin.gd (EditorPlugin)   <- _rpgm_plugin
	_show_rectangle()
	_update_rectangle_with_editor_state()
	_connect_rectangle_gui_input()
	
	# :C: no, the editor frees this script when _run returns,
	# so an await never resumes; connect rectangle.gui_input instead.
	

# i0i EditorInterface.get_base_control() is the root node
# for all visible editor nodes
var rectangle : ColorRect
func _show_rectangle():
	var _viewport := EditorInterface.get_base_control().get_viewport()
	if(rectangle): rectangle.queue_free()
	rectangle = ColorRect.new()
	rectangle.position = Vector2.ONE * 500
	rectangle.size = _viewport.get_visible_rect().grow(-500).size
	EditorInterface.get_base_control().add_child(rectangle)

	return rectangle


var _editor_root : Panel = EditorInterface.get_base_control()
var _label := Label.new()
func _update_rectangle_with_editor_state():
	
	_label.text += "selected_nodes:\n"
	for node : Node in EditorInterface.get_selection().get_selected_nodes():
		_label.text += "%s\n" % node.name
	
	print(_label.text)
	rectangle.add_child(_label)


func _connect_rectangle_gui_input():
	# :C: a local, so the lambda needs no script instance,
	# which the editor frees once _run returns.
	# var clicked_rectangle := rectangle
	# clicked_rectangle
	rectangle.gui_input.connect(
		func(input_event : InputEvent):
			if input_event is InputEventMouseButton and input_event.pressed:
				rectangle.queue_free()
			)
	
