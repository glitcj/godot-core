extends Node
class_name _Core_Turn

signal turn_finished

var doomer : _Core
var scene : _Core_Viewport

var turn_name : String
var turn_colour : Color
var turn_wait_time : float = 5.0
var show_in_turnboard : bool = true




func get_core(): return find_parent("_Core")

func _init() -> void:
	turn_name = "Turn"
	turn_colour = Color(1,1,1)


func start(_parent : Node):
	var parent = _parent
	parent.add_child(self)
	
	if parent is _Core_Viewport:
		scene = parent
	doomer = find_parent("_Core")
	
	on_turn_start()
	await turn_finished

func on_turn_start():
	pass

func on_turn_end():
	turn_finished.emit()
	queue_free()

func _process_input():
	pass
