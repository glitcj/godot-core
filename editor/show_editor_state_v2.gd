@tool
extends EditorScript

# i0i this editor script will be used
# to learn how to make nodes on the go
var rectangle_timeout := 5.

func _run() -> void:
	_show_rectangle()
	_connect_rectangle_gui_input()
	_show_editor_state()


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
	
	# fallback
	EditorInterface.get_base_control().get_tree().create_timer(5.).timeout.connect(rectangle.queue_free)

	return rectangle


var _editor_root : Panel = EditorInterface.get_base_control()
var _label := Label.new()
func _show_editor_state():
	
	_label.text += "selected_nodes:\n"
	for node : Node in EditorInterface.get_selection().get_selected_nodes():
		_label.text += "%s\n" % node.name
	
	print(_label.text)
	rectangle.add_child(_label)
	
	var panel := Panel.new()
	var vbox := VBoxContainer.new()
	var button = Button.new()
	
	

	# :C: after rectangle.add_child(panel), call
	# panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) to fill the rectangle.
	# :C: the rect is fine; the panel now covers it and
	# swallows the clicks, so set panel.mouse_filter = Control.MOUSE_FILTER_PASS.
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# i0i panel covers the rect and clicks on it
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.modulate = Color(0,0,0,.25)
	
	
	
	
	# i0i Controls like button must be added to their parent
	# BEFORE scaling/rotation pivots are adjusted, and BEFORE
	# attachment anchors and offsets are set. To make sure 
	# pivots and anchors are calculated correctly.
	rectangle.add_child(panel)
	panel.add_child(vbox)
	# vbox.add_child(button)
	panel.add_child(button)
	
	# :C: likely measured too early: outside the tree the button
	# has no editor theme, so move both calls after panel.add_child(button).
	button.pivot_offset = button.get_combined_minimum_size() / 2.


	
	# :C: an anchor is a point on the parent (0.5 = centre);
	# PRESET_CENTER then offsets the button by half its unscaled size.
	# :C: scale grows from pivot_offset, default top-left, so the
	# scaled button drifts off-centre unless pivot_offset is half its size.
	button.scale = Vector2.ONE * 50
	button.pressed.connect(func(): print("pressed i0i0"))
	

	
	
	# i0i a child's ANCHOR decides where ON THE PARENT the CENTER
	# of the child sits BEFORE scaling.
	# :C: the anchor only picks the point on the parent;
	# the offsets are what put the child's centre on it.
	# :C: this call set_anchors_and_offsets_preset sets both, with 
	# offsets of half the size;
	# :C: **set_anchors_preset** ALONE would put the TOP-LEFT 
	# corner there.
	# i0i a child's PIVOT decides what is SCALEs,
	# and ROTATEs, AROUND
	button.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	# :C: likely measured too early: outside the tree the button
	# has no editor theme, so move both calls after panel.add_child(button).
	# button.pivot_offset = button.get_combined_minimum_size() / 2.


	
	# _label.scale = Vector2.ONE * 5


# :C: the editor frees this script when _run returns,
# so an await never resumes; connect rectangle.gui_input instead.
func _connect_rectangle_gui_input():
	rectangle.gui_input.connect(
		func(input_event : InputEvent):
			if input_event is InputEventMouseButton and input_event.pressed:
				rectangle.queue_free()
			)
	
