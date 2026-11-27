@tool
extends EditorPlugin


var main_screen_root := Control.new()
func _enter_tree() -> void:
	EditorInterface.get_editor_main_screen().add_child(main_screen_root)
	_show_editor_state()
	# :A: yes, right spot, the panel must start hidden until
	# the editor shows the Core tab itself
	_make_visible(false)

# i0 must undo and delete everything created here
# or a root node can be defined and removed
func _exit_tree() -> void:
	main_screen_root.queue_free()

	
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
	main_screen_root.visible = visible
	
	
	
	
	
	
	
	
	
	
var panel := Panel.new()
var label := Label.new()
var button := Button.new()
func _show_editor_state():

	
	
	
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(label)
	panel.add_child(button)
	
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.pivot_offset = label.get_combined_minimum_size() / 2.
	label.scale = Vector2.ONE * 2
	label.text = "Core Editor\n"
	# label.text += "%s\n" % panel.get_tree_string_pretty().substr(0, 16)
	label.text += "%s\n" % get_tree_string_pretty().substr(0, 16)
	label.text += "%s\n" % get_parent() as String
	
	
	button.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	button.pivot_offset = button.get_combined_minimum_size() / 2.
	button.scale = Vector2.ONE * 5.
	button.name = "B1"
	button.pressed.connect(_Core_Editor.play_sfx)
	
	
	# :A: bare add_child adds to this plugin node, which is
	# a plain Node under EditorNode, not the main screen
	# :A: a Control without a Control parent is positioned from
	# the window origin, hence the editor's top left
	# :A: for the main screen use
	# EditorInterface.get_editor_main_screen().add_child(...), its VBoxContainer stacks them vertically
	# add_child(panel.duplicate())
	
	# i0 in EditorPlugin if you add a child it gets added
	# right under an EditorPlugin node that lives right
	# under the editor root: EditorNode
	
	var vbox := VBoxContainer.new()
	
	# bcs main_screen_root is a plain Control
	main_screen_root.size_flags_vertical = Control.SIZE_EXPAND_FILL 
	# bcs vbox is a Container
	# i0i :Q: so in this, the vbox says "i will place my center on the XXX of my parent ?"
	# :A: not its center, FULL_RECT says "pin each of my
	# four edges to the same edge of my parent"
	# :A: so vbox always matches the parent's size, with zero offsets
	# :A: PRESET_CENTER is the one saying "my center on
	# my parent's center", keeping my own size 
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) 
	# :A: yes, Panel is a plain Control, not a Container
	# :A: but the reason is the parent's type, not its own:
	# panel's parent vbox is a Container, so size_flags
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	
	
	# i0i to get the vbox filling the main screen:
	# :D: rule: parent is a Container, use size_flags;
	# parent is a plain Control, use anchors
	# :D: main_screen_root.size_flags_vertical = Control.SIZE_EXPAND_FILL since its parent
	# is the editor's VBoxContainer
	# :D: vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT) since its parent
	# main_screen_root is a plain Control
	# :D: each duplicate needs size_flags_vertical = Control.SIZE_EXPAND_FILL too,
	# or vbox gives the panels zero height
	main_screen_root.add_child(vbox)
	vbox.add_child(panel.duplicate())
	vbox.add_child(panel.duplicate())
	vbox.add_child(panel.duplicate())
	vbox.add_child(panel.duplicate())
	
	
	
	# :Q: what's the parent of main_screen_root ?
	# :A: get_editor_main_screen() itself is a VBoxContainer, and that
	# is main_screen_root's parent
	# :A: its own parent should be EditorMainScreen, a PanelContainer; check with
	# print(EditorInterface.get_editor_main_screen().get_parent().get_class())
	


	# :C: tells the main screen's VBoxContainer to give the panel
	# all spare height; containers ignore anchors, so without it height is zero.
	# main_screen_root.add_child(panel)
	# panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	
	


func _refresh():
	pass
