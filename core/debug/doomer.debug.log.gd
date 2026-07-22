extends Node
class_name _Doomer_Debug_Log

@onready var label : Label = find_child("Label")
@onready var doomer : _Core = find_parent("_Core")

enum LoggedKeys {
	current_turn,
	time_left,
}

var log : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_label()

func _update_label():
	label.text = ""
	for k in log.keys():
		label.text +=  "%s : %s" % [k, log[k]]
		
func _on_turn_updated():
	log["turn"] =  doomer.turner.current_turn
