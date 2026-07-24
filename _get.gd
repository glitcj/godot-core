extends Node
# class_name _Get # defined in autoload

static func core(node : Node): return node.find_parent("_Core") as _Core

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
