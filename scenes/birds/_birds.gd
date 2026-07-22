extends _Core_Viewport
class_name _Birds

signal finished

func get_hud(): return %_Core_Log as _Core_Log

func _ready() -> void:
	camera = %Camera2D as Camera2D

func _on_viewport_start():
	super()
	
func _on_viewport_end():
	super()
	
func finish():
	finished.emit()
