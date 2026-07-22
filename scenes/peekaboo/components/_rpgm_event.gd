@tool
extends Node2D
class_name _RPGM_Event


enum EventState {A, B, C, D, E, F, G}
@export var state : EventState = EventState.A


@onready var portraits = find_children("*", "_RPGM_Portrait")

var facing := Vector2(-1, 0):
	set(value):
		facing = value
		for p in portraits:
			if p: p.facing = facing
		


var is_collision = false
var deprecated = false

# CLAUDE: cached references to avoid repeated find_parent/find_child in per-frame calls
var _rpgm: _RPGM
var _map: _RPGM_Map
var _player: _RPGM_Player
var _area: Area2D
var _mover: _RPGM_Mover

func get_rpgm(): return _rpgm
func get_map(): return _map
func get_player(): return _player
func get_lambdas(): return _map.find_child("_RPGM_Lambdas") as _RPGM_Lambdas
func get_variables(): return _RPGM_Variables
func get_area(): return _area
func get_mover(): return _mover
func get_core(): return find_parent("_Core") as _Core

func get_portraits():
	# if not active_script: return null
	# return active_script.find_child("_RPGM_Portrait") as _RPGM_Portrait
	return null

var active_scripts := []
@onready var all_scripts = find_children("*", "_RPGM_Script")
var active_scripts_is_dirty = false
func update_active_scripts():
	active_scripts = []
	is_collision = false
	for s : _RPGM_Script in all_scripts:
		if not s: continue
		if s._is_active(): 
			active_scripts.append(s)
			is_collision = is_collision or s.is_collision

func _ready():
	_get_components.call_deferred()
	update_active_scripts.call_deferred()
	# get_core().get_log().add_log(func(): return name + str(portraits))

func _get_components():
	# CLAUDE: cache all node refs at ready to avoid repeated tree walks in per-frame calls
	# deferred so sibling nodes (e.g. Player) are in the tree before we search for them
	_rpgm = find_parent("_RPGM")
	_map = find_parent("_RPGM_Map")
	if _map: _player = _map.find_child("Player")
	_area = find_child("Area2D")
	_mover = find_child("_RPGM_Mover")

func _process(delta: float):
	if Engine.is_editor_hint(): return



func _child_entered_tree(_node: Node) -> void:
	notify_property_list_changed()

func _child_exiting_tree(_node: Node) -> void:
	notify_property_list_changed()

func _get_property_list() -> Array[Dictionary]:
	if not is_inside_tree(): return []
	var props: Array[Dictionary] = []
	if get_mover():
		props.append({
			"name": "_RPGM_Mover",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_CATEGORY
		})
		props.append({
			"name": "deprecated",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT
		})
	return props

func _get(property: StringName) -> Variant:
	if property == "deprecated": return deprecated
	return null

func _set(property: StringName, value: Variant) -> bool:
	if property == "deprecated":
		deprecated = value
		return true
	return false
