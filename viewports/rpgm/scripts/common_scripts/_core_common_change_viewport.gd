extends _RPGM_Script
class_name _Common_Script_Change_Viewport

signal returned_from_viewport_and_finished
var _core_viewport_name := "null"

func _init(_core_viewport_name_) -> void:
	_core_viewport_name = _core_viewport_name_
	interrupt_player = true


# disabled = true # TODO

# adjust _on_viewport_finished such that it takes in 
# the parameters returned from the connected _Core_Viewport
func _on_viewport_finished():
	get_core().change_viewport(get_rpgm())
	await get_rpgm().activated
	
	await get_lambdas().show_messages(["You neither won nor lost."])
	returned_from_viewport_and_finished.emit()


func _on_action():
	
	print(_core_viewport_name)
	var _viewport = get_core().get_scene(_core_viewport_name) as _Core_Viewport

	await get_mover().face(_get_direction_to_player())
	await get_lambdas().show_messages(["This will start the Mole Hole Mario Party mini game."])
	await get_tree().create_timer(1).timeout
	
	_viewport.finished.connect(_on_viewport_finished, CONNECT_ONE_SHOT)
	get_core().change_viewport(get_core().get_scene(_core_viewport_name))
	await returned_from_viewport_and_finished
