@tool
extends EditorPlugin

var _rpgm_v1 := preload("res://addons/_rpgm_v1/_rpgm_v1.tscn")
var panel : Control
# CLAUDE: inspector plugin that lays out the _RPGM_Mover quantise buttons in one row
var mover_inspector := preload("res://addons/_rpgm_v1/mover_inspector_plugin.gd").new()

func _enter_tree():
	# mover quantise buttons
	add_inspector_plugin(mover_inspector)
	
	
	# i0 node inspection dock
	panel = _rpgm_v1.instantiate()
	add_control_to_bottom_panel(panel, "_rpgm_v1")

func _exit_tree():
	remove_inspector_plugin(mover_inspector)
	remove_control_from_bottom_panel(panel)
	panel.queue_free()
