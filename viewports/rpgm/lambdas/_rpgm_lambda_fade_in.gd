extends _RPGM_Lambda
class_name _RPGM_Lambda_Fade_In

# CLAUDE: ported from _RPGM_Callables.fade_in — no inputs. Like the callable,
# it starts the tween and returns without waiting for it to finish.
# CLAUDE: parameter widened from _RPGM_Script to _RPGM_Node (see _RPGM_Lambda)
func run(rpgm_node : _RPGM_Node):
	_Core_Tweener.fade_in(rpgm_node.get_rpgm())
