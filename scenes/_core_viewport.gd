extends SubViewportContainer
class_name _Core_Viewport

signal activated
signal deactivated
signal started
# the signal <finished> is to be defined within 
# each child of _Core_Viewport



# REFACTOR: Do we really need start AND activate 
# as concepts ?also do we really end, finished, 
# and Deactivated as concepts ? may be over engineered 
# here no ? Actually we need the de/activation stuff, 
# but deprecate finished ?

func _ready() -> void:
	assert(has_signal("finished"))
	# _on_viewport_start()

var is_active = false

@onready var core : _Core = find_parent("_Core")
@onready var camera : Camera2D

func _on_viewport_start():
	await get_tree().process_frame
	started.emit()
	await get_tree().process_frame
	_activate()
	
func _on_viewport_finish():
	await get_tree().process_frame
	_deactivate()
	# cant emit finished here because its
	# defined per class, what does this mean for
	# sequence ? Make doc clearly showing this
	# expected pattern. 
	# Make Doc for all core functionality.
	# Start > Activate > Deactivate > Finish



	
# de/activation is needed in cases where the scene is paused and not finished
func _activate():
	is_active = true
	activated.emit()

func _deactivate():
	is_active = false
	deactivated.emit()
