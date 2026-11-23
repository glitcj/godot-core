extends _RPGM_Lambda
class_name _RPGM_Lambda_Transport_Camera

# CLAUDE: ported from _RPGM_Callables.transport_camera. A lambda saved in a
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
		push_error("_RPGM_Lambda_Transport_Camera: no target at '%s'" % target_path)
		return
	assert(target is _RPGM_Event or target is _RPGM_Player)

	var player = rpgm_node.get_player()
	var map = rpgm_node.get_rpgm()
	if target is _RPGM_Event:
		(player.find_child("RemoteTransform2D") as RemoteTransform2D).update_position = false
		map.find_child("_RPGM_Camera").find_child("Camera2D").position = Vector2.ZERO
		# the camera node (an _RPGM_Event) IS the mover (mixin refactor)
		var camera_mover = map.find_child("_RPGM_Camera") as _RPGM_Mover
		camera_mover.teleport(target.get_mover().map_position)

	if target is _RPGM_Player:
		(player.find_child("RemoteTransform2D") as RemoteTransform2D).update_position = true
