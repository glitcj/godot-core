extends SubViewportContainer
class_name _Core_Viewport

signal activated
signal deactivated
signal started
# the signal <finished> is to be defined within 
# each child of _Core_Viewport



func _ready() -> void:
	assert(has_signal("finished"))
	_on_viewport_start()

var is_active = false

"""
var is_active = false:
	set(v):
		is_active = v
		if is_active:
			await _activate()
			activated.emit()

		else:
			await _deactivate()
			deactivated.emit()
"""


@onready var core : _Core = find_parent("_Core")
@onready var camera : Camera2D

func _on_viewport_start():
	await get_tree().process_frame
	# is_active = true
	_activate()
	started.emit()
	
func _on_viewport_end():
	await get_tree().process_frame
	# is_active = false
	_deactivate()
	
	
# de/activation is needed in cases where the scene is paused and not finished
func _activate():
	is_active = true
	activated.emit()

func _deactivate():
	is_active = false
	deactivated.emit()
