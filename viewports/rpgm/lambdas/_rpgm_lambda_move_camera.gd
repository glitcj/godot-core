extends _RPGM_Lambda
class_name _RPGM_Lambda_Move_Camera

# CLAUDE: ported from _RPGM_Callables.move_camera — same pattern as
# _RPGM_Lambda_Show_Messages: the default lives on the @export line, and
# _init only overrides it when a code caller passes a value.
@export var delta : Vector2i = Vector2i.ZERO

func _init(delta_ = null):
	delta = delta_ if delta_ != null else delta

# CLAUDE: parameter widened from _RPGM_Script to _RPGM_Node (see _RPGM_Lambda)
func run(rpgm_node : _RPGM_Node):
	# the camera node (an _RPGM_Event) IS the mover (mixin refactor)
	var mover = rpgm_node.get_rpgm().find_child("_RPGM_Camera") as _RPGM_Mover
	await mover.move(delta)
