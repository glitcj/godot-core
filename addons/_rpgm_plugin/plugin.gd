@tool
extends EditorPlugin

var _bottom_dock_control : Control
var _main_screen_control : Control


# i0 PackedScene.instantiate() creates solid
# script nodes
const MAIN_SCREEN : PackedScene = preload("res://addons/_rpgm_plugin/_rpgm_plugin_main_screen/_rpgm_plugin_main_screen.tscn")
const BOTTOM_DOCK : PackedScene = preload("res://addons/_rpgm_plugin/_rpgm_plugin_bottom_dock/_rpgm_plugin_bottom_dock.tscn")

# i0 GDScript.new() creates a dimmed script node, 
# because it is made from GDScript
var INSPECTOR : GDScript = preload("res://addons/_rpgm_plugin/_rpgm_plugin_inspector/_rpgm_plugin_inspector.gd")


func _enter_tree():
		_main_screen_control = MAIN_SCREEN.instantiate()
		EditorInterface.get_editor_main_screen().add_child(_main_screen_control)
		_make_visible(false) # hidden until its tab is clicked

		_bottom_dock_control = BOTTOM_DOCK.instantiate()
		add_control_to_bottom_panel(_bottom_dock_control, "RPGM")

		add_inspector_plugin(INSPECTOR.new())


func _exit_tree():
	if _main_screen_control: _main_screen_control.queue_free()
	remove_inspector_plugin(INSPECTOR.new())
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
