@tool
# CLAUDE: the one place that knows how to name, summarise, list and create
# lambdas for the editor. The dock's queue editor and the Inspector row both
# call it, so they can never describe the same lambda differently.
#
# LESSON: put "how do I describe this data" in one helper; every view calls it.
#
# LESSON: lambda scripts are not @tool, so inside the editor a lambda is only
# a placeholder: its values are there, its code is not. Ask the SCRIPT what
# a lambda has (exported_properties), ask the INSTANCE what its values are
# (get / set), and never call its methods.
extends Object
class_name _RPGM_Plugin_Lambda_Text

const BASE_CLASS := &"_RPGM_Lambda"
const NAME_PREFIX := "_RPGM_Lambda_"


# ---------------------------------------------------------------- describing

# _RPGM_Lambda_Show_Messages -> Show Messages
static func friendly_class_name(global_name : String) -> String:
	if global_name == String(BASE_CLASS): return "Lambda"
	return global_name.trim_prefix(NAME_PREFIX).replace("_", " ")


static func friendly_name(lambda : Resource) -> String:
	if lambda == null: return "<empty>"
	var script := lambda.get_script() as Script
	if script == null: return lambda.get_class()
	var global_name := String(script.get_global_name())
	if global_name.is_empty(): return script.resource_path.get_file().get_basename()
	return friendly_class_name(global_name)


# on_action -> On Action,  _scale -> Scale
static func friendly_property_name(property : StringName) -> String:
	return String(property).trim_prefix("_").capitalize()


# One line describing the lambda's values, e.g.  "Hello", "Bye"
# A lone value is shown bare; several are labelled so they can be told apart.
static func summary(lambda : Resource) -> String:
	var properties := exported_properties(lambda)
	if properties.size() == 1:
		return _value_text(lambda.get(properties[0].name))
	var parts : PackedStringArray = []
	for p in properties:
		parts.append("%s %s" % [friendly_property_name(p.name), _value_text(lambda.get(p.name))])
	return "  ·  ".join(parts)


static func _value_text(value : Variant) -> String:
	if value is String or value is StringName:
		return '"%s"' % value
	if value is Array:
		var parts : PackedStringArray = []
		for element in value: parts.append(_value_text(element))
		return ", ".join(parts)
	var text := str(value)
	return text if not text.is_empty() else "—"


# ---------------------------------------------------------------- discovering

# LESSON: discover instead of listing. A new @export on a lambda, a new lambda
# class, or a new queue on the node shows up without editing the plugin.

# The lambda's @export values.
# CLAUDE: read from the script, not the instance. The instance is a
# placeholder in the editor and its property list did not carry the
# script-variable flag this used to filter on, so every lambda looked like
# it had no values: no summary in the list, nothing to edit in the pane.
# The script's own list has no built-ins (resource_name, ...), and the
# EDITOR flag keeps the @export ones while dropping plain vars and groups.
static func exported_properties(lambda : Resource) -> Array[Dictionary]:
	var properties : Array[Dictionary] = []
	if lambda == null: return properties
	var script := lambda.get_script() as Script
	if script == null: return properties
	for p in script.get_script_property_list():
		if not (p.usage & PROPERTY_USAGE_EDITOR): continue
		properties.append(p)
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


# Every global class whose base chain reaches _RPGM_Lambda, sorted by name.
# Each entry: { "name" : String, "path" : String }
static func lambda_classes() -> Array[Dictionary]:
	var bases : Dictionary = {}
	var paths : Dictionary = {}
	for global_class in ProjectSettings.get_global_class_list():
		bases[String(global_class["class"])] = String(global_class["base"])
		paths[String(global_class["class"])] = String(global_class["path"])

	var names : Array[String] = []
	for global_name in bases:
		var base : String = bases[global_name]
		while base != String(BASE_CLASS) and bases.has(base): base = bases[base]
		if base == String(BASE_CLASS): names.append(global_name)
	names.sort()

	var classes : Array[Dictionary] = []
	for global_name in names:
		classes.append({ "name" : global_name, "path" : paths[global_name] })
	return classes


# ---------------------------------------------------------------- creating

# Attaches the script to a plain Resource instead of calling Script.new():
# that gives the same placeholder a saved scene would load, with the @export
# defaults filled in, and does not run the game's _init() inside the editor.
static func new_lambda(script_path : String) -> Resource:
	var lambda := Resource.new()
	lambda.set_script(load(script_path))
	return lambda
