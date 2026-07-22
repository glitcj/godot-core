extends _Core_Turn
class_name _Core_Turn_Lambda

var to_call : Callable
var to_bind : Array
var wait_for_call : bool

func _init(to_call_ : Callable, to_bind_ : Array = [], wait_for_call_ : bool = true) -> void:
	super()
	turn_name = "LMD"
	turn_colour = Color(0.5,.3,.5)
	name = "_Core_Turn_Lambda"
	turn_wait_time = _Doomer_Constants.immediate_action_time_delta

	to_call = to_call_
	to_bind = to_bind_
	wait_for_call = wait_for_call_

func on_turn_start():
	await get_tree().create_timer(turn_wait_time).timeout

	# TODO: Deep loop through to_bind if you runtime variables are needed
	# bindv is bind vector which accepts parameters as an array
	if wait_for_call:
		await to_call.bindv(to_bind).call()
	else:
		to_call.bind(to_bind).call()

	on_turn_end()
