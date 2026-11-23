@tool
extends EditorPlugin

# var _rpgm_v2 := preload("res://addons/_rpgm_v2/_rpgm_v2.tscn")
var panel : Control
var screen : Control




const MAIN_SCREEN : PackedScene = preload("res://addons/_rpgm_v2/_rpgm_plugin_main_screen/_rpgm_plugin_main_screen.tscn")
const BOTTOM_DOCK : PackedScene = preload("res://addons/_rpgm_v2/_rpgm_plugin_bottom_dock/_rpgm_plugin_bottom_dock.tscn")



# CLAUDE: inspector plugin that lays out the _RPGM_Mover quantise buttons in one row


# io the following hooks must live in the .gd pointed at by plugin.cfg
# _has_main_screen(), _get_plugin_name(), 
# _get_plugin_icon(),  _make_visible()
# _enter_tree(), _exit_tree()


var mover_inspector := preload("res://addons/_rpgm_v2/_rpgm_plugin_inspector/_rpgm_plugin_inspector.gd").new()

# CLAUDE: removed the bottom_plugin .new() line — it created a node that was
# never added to the tree or freed


func _enter_tree():
		# screen = preload("res://addons/_rpgm_v2/_rpgm_v2.tscn").instantiate()
		# EditorInterface.get_editor_main_screen().add_child(screen)
		
		screen = MAIN_SCREEN.instantiate()
		EditorInterface.get_editor_main_screen().add_child(screen)


		_make_visible(false)          # hidden until its tab is clicked
		
		# mover quantise buttons
		add_inspector_plugin(mover_inspector)
		# add_inspector_plugin(mover_inspector)
	
		# i0 node inspection dock
		# panel = _rpgm_v2.instantiate()
		# add_control_to_bottom_panel(panel, "_rpgm_v2")

		panel = BOTTOM_DOCK.instantiate()
		add_control_to_bottom_panel(panel, "_rpgm_v2")


func _exit_tree():
	if screen: screen.queue_free()
	remove_inspector_plugin(mover_inspector)
	remove_control_from_bottom_panel(panel)
	panel.queue_free()

func _has_main_screen() -> bool: return true          # "give me a tab"
func _get_plugin_name() -> String: return "Events"    # the tab's label
func _get_plugin_icon() -> Texture2D:
		return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")
func _make_visible(visible : bool) -> void:           # the editor calls this on tab switch
		if screen: screen.visible = visible
