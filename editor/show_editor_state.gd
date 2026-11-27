@tool
extends EditorScript

var rectangle_timeout := 5.

func _run() -> void:
	_show_rectangle()
	_connect_rectangle_gui_input()
	_show_editor_state()

var rectangle : ColorRect
func _show_rectangle():
	var _viewport := EditorInterface.get_base_control().get_viewport()
	if(rectangle): rectangle.queue_free()
	rectangle = ColorRect.new()
	rectangle.position = Vector2.ONE * 500
	rectangle.size = _viewport.get_visible_rect().grow(-500).size
	EditorInterface.get_base_control().add_child(rectangle)
	
	# i0i fallback
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
	
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# i0i panel covers the rect and clicks on it
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.modulate = Color(0,0,0,.05)
	
	rectangle.add_child(panel)
	panel.add_child(vbox)
	# vbox.add_child(button)
	panel.add_child(button)
	
	button.pivot_offset = button.get_combined_minimum_size() / 2.
	button.scale = Vector2.ONE * 5
	button.pressed.connect(_Core_Editor.play_sfx)
	
	button.pressed.connect(func(): print("pressed i0i0"))
	button.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	_Core_Editor.play_sfx("res://assets/ninja/Sounds/Game/Alert2.wav")
	
func _connect_rectangle_gui_input():
	rectangle.gui_input.connect(
		func(input_event : InputEvent):
			if input_event is InputEventMouseButton and input_event.pressed:
				rectangle.queue_free()
			)
	
