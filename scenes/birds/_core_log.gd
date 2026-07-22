extends PanelContainer
class_name _Core_Log

var vector_log_scene = preload("res://scenes/birds/_core_log_item.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_log(to_log : Callable):
	var _log = vector_log_scene.instantiate()
	_log.to_log = to_log
	%VBoxContainer.add_child(_log)
