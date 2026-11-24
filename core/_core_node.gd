extends Node2D
class_name _Core_Node

func _log(message : String):
	pass
	print("[%s %s] %s" % [get_class(), self, message])
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
