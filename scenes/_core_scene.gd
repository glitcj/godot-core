extends SubViewportContainer
class_name _Core_Viewport

signal activated
signal deactivated
signal started
# the signal <finished> is to be defined within 
# each child of _Core_Viewport

var is_active = false:
	set(v):
		is_active = v
		if is_active:
			await _activate()
			activated.emit()

		else:
			await _deactivate()
			deactivated.emit()

@onready var core : _Core = find_parent("_Core")
@onready var camera : Camera2D

func _on_viewport_start():
	await get_tree().process_frame
	is_active = true
	started.emit()
	
func _on_viewport_end():
	await get_tree().process_frame
	is_active = false
	
# de/activation is needed in cases where the scene is paused and not finished
func _activate():
	pass

func _deactivate():
	pass
