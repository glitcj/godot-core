extends _Core_Turn
class_name _Starter_Turn

var accepted_inputs = [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]
var wait_amount : float = .2

func _init() -> void:
	super()
	turn_name = "SCN"
	turn_colour = Color(0.5,.3,.5)
	turn_wait_time = .2


func on_turn_start():
	pass

func _input(event: InputEvent) -> void:
	if get_parent().has_method("is_active") and not get_parent().is_active:
		return
	if not event is InputEventKey: return
	if not (event.pressed and not event.echo): return
	
	if (event as InputEventKey).keycode in accepted_inputs:
		await get_core().change_viewport((get_parent() as _Starter).next_scene)
		on_turn_end()
		
