@tool
# CLAUDE: what the editor needs to know about lambdas: their class name, their
# @export values, which properties are lambda queues, which classes exist.
extends Object
class_name _RPGM_Plugin_Lambda_Text

const BASE_CLASS := &"_RPGM_Lambda"


# CLAUDE: the raw class name, e.g. _RPGM_Lambda_Show_Messages. Replaces the
# friendly_* functions; the UI now shows the same names the scripts use.
static func class_name_of(lambda : Resource) -> String:
	if lambda == null: return "<empty>"
	return String((lambda.get_script() as Script).get_global_name())


# LESSON: lambda scripts are not @tool, so in the editor a lambda is only a
# placeholder. Read its @export list from the script, its values with get().
static func exported_properties(lambda : Resource) -> Array[Dictionary]:
	var properties : Array[Dictionary] = []
	if lambda == null: return properties
	for p in (lambda.get_script() as Script).get_script_property_list():
		if p.usage & PROPERTY_USAGE_EDITOR: properties.append(p)
	return properties


# True for an Array[_RPGM_Lambda] (or an array of one of its subclasses).
static func is_lambda_queue(value : Variant) -> bool:
	if not value is Array: return false
	var script := (value as Array).get_typed_script() as Script
	while script != null:
		if script.get_global_name() == BASE_CLASS: return true
		script = script.get_base_script()
	return false


# Names of the node's lambda queue properties, in declaration order.
static func queue_properties(node : Object) -> Array[StringName]:
	var names : Array[StringName] = []
	if node == null: return names
	for p in node.get_property_list():
		if p.type != TYPE_ARRAY: continue
		if not (p.usage & PROPERTY_USAGE_EDITOR): continue
		if is_lambda_queue(node.get(p.name)): names.append(StringName(p.name))
	return names


# CLAUDE: one pass over the project's class list instead of building, sorting
# and re-packing. Returns the entries as they are: { "class", "base", "path" }.
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


# Attaches the script to a plain Resource instead of calling Script.new(), so
# the game's _init() does not run inside the editor.
static func new_lambda(script_path : String) -> Resource:
	var lambda := Resource.new()
	lambda.set_script(load(script_path))
	return lambda
