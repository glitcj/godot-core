extends Node
class_name _Core_Turner

@onready var doomer : _Core = find_parent("_Core")

var last_turn : _Core_Turn
var current_turn : _Core_Turn
var next_turn : _Core_Turn

var processed_turns : Array[_Core_Turn] = []
var turn_queue = []


func _ready() -> void:
	turn_queue = []

func start_next_turn():
	if current_turn != null:
		last_turn = current_turn
		processed_turns.append(current_turn)
		remove_child(last_turn)

	if turn_queue == []:
		return

	current_turn = turn_queue.pop_front()
	add_child(current_turn)

	if not turn_queue == []:
		next_turn = turn_queue[0]

	if last_turn != null:
		await last_turn.on_turn_end()
	await current_turn.on_turn_start()

func _update_hud():
	if not current_turn.show_in_turnboard:
		return

func insert_turn(_turn : _Core_Turn, _position = 0):
	turn_queue.insert(_position, _turn)

func insert_lambda(_callable : Callable):
	insert_turn(_Core_Turn_Lambda.new(_callable))
