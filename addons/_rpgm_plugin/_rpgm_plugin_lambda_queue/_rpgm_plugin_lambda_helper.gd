@tool
# :C: static helpers for what the editor
# needs to know about lambdas.
extends Object
class_name _RPGM_Plugin_Lambda_Helper

# :C: the lambda queues of _RPGM_Script, in tab order;
# keep in sync with its @exports.
const LAMBDA_QUEUE_PROPERTIES : Array[StringName] = [
	&"on_action", &"on_frame", &"on_area_entered", &"on_within_area"]


# :C: the lambda's class name, e.g. _RPGM_Lambda_Show_Messages.
static func class_name_of(lambda : Resource) -> String:
	if lambda == null: return "<empty>"
	return String((lambda.get_script() as Script).get_global_name())

# i0 generates a new script by making a Resource.new()
# then attaching the script, skips _init() while the
# editor is running.
# :C: set_script on a plain Resource,
# so the game's _init() does not run in editor.
static func new_lambda(script_path : String) -> Resource:
	var lambda := Resource.new()
	lambda.set_script(load(script_path))
	return lambda
