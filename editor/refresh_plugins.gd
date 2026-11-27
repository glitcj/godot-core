@tool
extends EditorScript


func _run() -> void:
	EditorInterface.set_plugin_enabled("_core_editor", false)
	
	# :A: the await fails because the editor frees this EditorScript
	# once _run returns, so the line after never runs
	# :A: without it the new panel starts visible alongside the
	# current main screen, so it stacks underneath it
	# :A: the plugin's _enter_tree should call _make_visible(false) after
	# add_child, as the Godot main screen plugin docs do
	# :A: or here, after enabling, switch to it with
	# EditorInterface.set_main_screen_editor("Core")
	# await EditorInterface.get_base_control().get_tree().create_timer(.5).timeout
	EditorInterface.set_plugin_enabled("_core_editor", true)
	EditorInterface.set_main_screen_editor("Core")
