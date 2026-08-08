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
	# scenes boot suspended; _activate() wakes the current one
	_suspend()

var is_active = false

@onready var core : _Core = find_parent("_Core")
@onready var camera : Camera2D
@onready var sub_viewport : SubViewport = find_child("SubViewport")


func _on_viewport_start():
	await get_tree().process_frame
	started.emit()
	await get_tree().process_frame
	# if not keep_running: _resume()
	_activate()
	
func _on_viewport_finish():
	await get_tree().process_frame
	_deactivate()
	# if not keep_running: _suspend()
	
	# cant emit finished here because its
	# defined per class, what does this mean for
	# sequence ? Make doc clearly showing this
	# expected pattern. 
	# Make Doc for all core functionality.
	# Start > Activate > Deactivate > Finish
	
# de/activation is needed in cases where the scene is paused and not finished
func _activate():
	is_active = true
	# _resume()
	activated.emit()

func _deactivate():
	is_active = false
	deactivated.emit()
	# _suspend()

# a suspended viewport neither renders nor processes, so inactive
# scenes (especially 3d ones) cost nothing per frame.
# signals and coroutine resumption still work while suspended,
# but audio keeps playing and must be stopped by the scene itself
func _suspend():
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	# CLAUDE: set_deferred — _suspend can be reached from inside a physics
	# callback (DGM Area3D.area_entered -> finished -> change_viewport), and
	# disabling CollisionObjects mid-physics-flush is not allowed; deferring
	# applies the change after the physics step
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

func _resume():
	process_mode = Node.PROCESS_MODE_INHERIT
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
