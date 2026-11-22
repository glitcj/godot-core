extends _RPGM_Lambda
class_name _RPGM_Lambda_Fade_In

# CLAUDE: ported from _RPGM_Callables.fade_in — no inputs. Like the callable,
# it starts the tween and returns without waiting for it to finish.
func run(rpgm_script : _RPGM_Script):
	_Core_Tweener.fade_in(rpgm_script.get_map())
