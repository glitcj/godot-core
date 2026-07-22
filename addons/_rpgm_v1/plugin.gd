@tool
extends EditorPlugin

var _rpgm_v1 := preload("res://addons/_rpgm_v1/_rpgm_v1.tscn")
var panel : Control

func _enter_tree():
	# panel = Control.new()
	panel = _rpgm_v1.instantiate()
	add_control_to_bottom_panel(panel, "_rpgm_v1")

func _exit_tree():
	remove_control_from_bottom_panel(panel)
	panel.queue_free()
