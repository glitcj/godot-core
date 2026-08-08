@tool
extends Node2D
class_name _RPGM_Node

# CLAUDE: shared base for the RPGM Node2D family (mover, event, script,
# player) — defines the lazy cached getters once instead of each class
# reimplementing them. _cached resolves a ref on first use and re-resolves
# if it was freed.
var _refs := {}
func _cached(key: StringName, finder: Callable) -> Node:
	if not is_instance_valid(_refs.get(key)): _refs[key] = finder.call()
	return _refs[key]

func get_rpgm() -> _RPGM: return _cached(&"rpgm", func(): return find_parent("_RPGM")) as _RPGM
func get_map() -> _RPGM_Map: return _cached(&"map", func(): return find_parent("_RPGM_Map")) as _RPGM_Map
func get_player() -> _RPGM_Player: return _cached(&"player", func(): return get_map().find_child("Player") if get_map() else null) as _RPGM_Player
func get_core() -> _Core: return _cached(&"core", func(): return find_parent("_Core")) as _Core
func get_lambdas() -> _RPGM_Lambdas: return _cached(&"lambdas", func(): return get_map().find_child("_RPGM_Lambdas") if get_map() else null) as _RPGM_Lambdas
func get_area() -> Area2D: return _cached(&"area", func(): return find_child("Area2D")) as Area2D
# CLAUDE: mover is no longer a child node — _RPGM_Event/_RPGM_Player extend
# _RPGM_Mover directly, so the node itself is the mover (null for non-movers)
func get_mover() -> _RPGM_Mover: return self as _RPGM_Mover
func get_portrait() -> _RPGM_Portrait: return _cached(&"portrait", func(): return find_child("_RPGM_Portrait")) as _RPGM_Portrait
func get_variables(): return _RPGM_Variables
