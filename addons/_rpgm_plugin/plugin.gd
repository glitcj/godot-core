@tool
extends EditorPlugin

# CLAUDE: the EditorPlugin is the table of contents: it registers things in
# _enter_tree and unregisters the same things in _exit_tree.

var _bottom_dock_control : _RPGM_Plugin_Bottom_Dock
var _main_screen_control : _RPGM_Plugin_Main_Screen


# i0 PackedScene.instantiate() creates solid
# script nodes
const MAIN_SCREEN : PackedScene = preload("res://addons/_rpgm_plugin/_rpgm_plugin_main_screen/_rpgm_plugin_main_screen.tscn")
const BOTTOM_DOCK : PackedScene = preload("res://addons/_rpgm_plugin/_rpgm_plugin_bottom_dock/_rpgm_plugin_bottom_dock.tscn")

# i0 GDScript.new() creates a dimmed script node, 
# because it is made from GDScript
var INSPECTOR : GDScript = preload("res://addons/_rpgm_plugin/_rpgm_plugin_inspector/_rpgm_plugin_inspector.gd")
# CLAUDE: second inspector plugin — readable lambda queue rows on _RPGM_Script
var SCRIPT_INSPECTOR : GDScript = preload("res://addons/_rpgm_plugin/_rpgm_plugin_inspector/_rpgm_plugin_script_inspector.gd")

# LESSON: keep the registered instances; _exit_tree must remove the same ones.
var _mover_inspector : EditorInspectorPlugin
var _script_inspector : EditorInspectorPlugin


func _enter_tree():
		_main_screen_control = MAIN_SCREEN.instantiate()
		EditorInterface.get_editor_main_screen().add_child(_main_screen_control)
		_make_visible(false) # hidden until its tab is clicked

		# _bottom_dock_control : _RPGM_Plugin_Bottom_Dock = BOTTOM_DOCK.instantiate()
		_bottom_dock_control = BOTTOM_DOCK.instantiate() as _RPGM_Plugin_Bottom_Dock
		add_control_to_bottom_panel(_bottom_dock_control, "RPGM")
		_bottom_dock_control.bottom_dock_requested.connect(func(): make_bottom_panel_item_visible(_bottom_dock_control))
		
		var _rpgm_dock = _bottom_dock_control
		_bottom_dock_control.rpgm_dock_requested.connect(func(): make_bottom_panel_item_visible(_rpgm_dock))
		
		
		var _show_output_tab = func():
			var output := EditorInterface.get_base_control().find_children("*", "EditorLog", true, false)
			if not output.is_empty(): output[0].make_visible()
		_bottom_dock_control.output_bottom_dock_requested.connect(_show_output_tab)		




		_mover_inspector = INSPECTOR.new()
		add_inspector_plugin(_mover_inspector)

		# CLAUDE: the Inspector row's "Edit in RPGM dock" button ends up here.
		_script_inspector = SCRIPT_INSPECTOR.new()
		_script_inspector.edit_requested.connect(_bottom_dock_control.show_queue)
		add_inspector_plugin(_script_inspector)


func _exit_tree():
	if _main_screen_control: _main_screen_control.queue_free()
	remove_inspector_plugin(_mover_inspector)
	remove_inspector_plugin(_script_inspector)
	remove_control_from_bottom_panel(_bottom_dock_control)
	_bottom_dock_control.queue_free()

func _has_main_screen() -> bool: 
	return true          # "give me a tab"
func _get_plugin_name() -> String: 
	return "RPGM"    # the tab's label
func _get_plugin_icon() -> Texture2D:
		return EditorInterface.get_editor_theme().get_icon("TextureRect", "EditorIcons")
func _make_visible(visible : bool) -> void:           # the editor calls this on tab switch
		if _main_screen_control: _main_screen_control.visible = visible
