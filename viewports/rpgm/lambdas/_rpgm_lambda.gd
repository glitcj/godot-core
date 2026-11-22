extends _Core_Lambda
class_name _RPGM_Lambda

# CLAUDE: run() takes any _RPGM_Node (was _RPGM_Script) so _RPGM_Node.run_lambda
# works from events and the player too — lambdas only use the get_*() getters
func run(rpgm_node : _RPGM_Node):
	_log("%s ran %s of class %s." % [rpgm_node, self, get_class()])

func _log(message):
	print( "[_RPGM_Lambda %s]: %s"  % [self, message])
