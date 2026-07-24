extends _Core_Viewport
class_name _Birds

signal finished

func get_hud(): return %_Core_Log as _Core_Log
func get_core(): return find_parent("_Core") as _Core

func _ready() -> void:
	super()
	camera = %Camera2D as Camera2D
	get_core().get_log().add_log(func tester(): return "is_active: %s" % is_active)


func _on_viewport_start():
	super()
	
	
func _on_viewport_finish():
	super()
	
func finish():
	finished.emit()
