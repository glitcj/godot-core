extends _RPGM_Lambda
class_name _RPGM_Lambda_Transport_Player

# CLAUDE: ported from _RPGM_Callables.transport_player. A lambda saved in a
# scene can't hold a node reference, so the Inspector field is a NodePath
# (resolved relative to the script node that runs the lambda). Code callers
# can pass the node itself to .new(node); it is kept in _target, unsaved.
@export var target_path : NodePath
var _target : Node

func _init(target_ = null):
	if target_ is Node: _target = target_
	elif target_ != null: target_path = NodePath(target_)

# CLAUDE: parameter widened from _RPGM_Script to _RPGM_Node (see _RPGM_Lambda)
func run(rpgm_node : _RPGM_Node):
	var target = _target if _target else rpgm_node.get_node_or_null(target_path)
	if target == null:
		push_error("_RPGM_Lambda_Transport_Player: no target at '%s'" % target_path)
		return
	assert(target is _RPGM_Event)
	# the player IS the mover (mixin refactor)
	var player_mover = rpgm_node.get_player() as _RPGM_Mover
	player_mover.teleport(target.get_mover().map_position)
