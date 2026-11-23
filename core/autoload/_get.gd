extends Node
# class_name grab # defined in autoload

static func core(node : Node): return node.find_parent("_Core") as _Core
static func map(node : Node): return node.find_parent("_RPGM") as _RPGM
static func event(node : Node): return node.get_parent() as _RPGM_Event
