@tool
# CLAUDE: what the editor needs to know about lambdas, as static helpers.
extends Object
class_name _RPGM_Plugin_Lambda_Inspector

const BASE_CLASS := &"_RPGM_Lambda"

# CLAUDE: the lambda queues of _RPGM_Script in tab order; keep in sync with its @exports.
const LAMBDA_QUEUE_PROPERTIES : Array[StringName] = [
	&"on_action", &"on_frame", &"on_area_entered", &"on_within_area"]


# CLAUDE: the lambda's class name, e.g. _RPGM_Lambda_Show_Messages.
static func class_name_of(lambda : Resource) -> String:
	if lambda == null: return "<empty>"
	return String((lambda.get_script() as Script).get_global_name())


# CLAUDE: lambda scripts are not @tool, so the @export list is read from the script.
static func exported_properties(lambda : Resource) -> Array[Dictionary]:
	var properties : Array[Dictionary] = []
	for p in (lambda.get_script() as Script).get_script_property_list():
		if p.usage & PROPERTY_USAGE_EDITOR: properties.append(p)
	return properties


# CLAUDE: every global class that inherits _RPGM_Lambda, as { "class", "base", "path" }.
static func lambda_classes() -> Array[Dictionary]:
	var all := ProjectSettings.get_global_class_list()
	var base_of := {}
	for c in all: base_of[String(c["class"])] = String(c["base"])

	var found : Array[Dictionary] = []
	for c in all:
		var base := String(c["base"])
		while base != BASE_CLASS and base_of.has(base): base = base_of[base]
		if base == BASE_CLASS: found.append(c)
	return found


# CLAUDE: set_script on a plain Resource so the game's _init() does not run in the editor.
static func new_lambda(script_path : String) -> Resource:
	var lambda := Resource.new()
	lambda.set_script(load(script_path))
	return lambda
