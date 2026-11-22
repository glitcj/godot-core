extends Resource
class_name _Core_Lambda

# CLAUDE: run() takes any _RPGM_Node (was _RPGM_Script) so _RPGM_Node.run_lambda
# works from events and the player too — lambdas only use the get_*() getters
func run(rpgm_node : _RPGM_Node):
	return
