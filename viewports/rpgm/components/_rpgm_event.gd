@tool
@icon("res://addons/at-icons/animation/box_wireframe.svg")
# CLAUDE: extends _RPGM_Node — all get_*() lazy cached getters now inherited
extends _RPGM_Node
class_name _RPGM_Event

enum EventState {A, B, C, D, E, F, G}
@export var state : EventState = EventState.A

@onready var portraits = find_children("*", "_RPGM_Portrait")

var facing := Vector2(-1, 0):
	set(value):
		facing = value
		for p in portraits: if p: p.facing = facing
		
var is_collision = false
# var deprecated = false

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
	if Engine.is_editor_hint(): return # new
	update_active_scripts.call_deferred()
	# get_core().get_log().add_log(func(): return name + str(portraits))

func _process(delta: float):
	if Engine.is_editor_hint(): return
	
func _child_entered_tree(_node: Node) -> void:
	notify_property_list_changed()

func _child_exiting_tree(_node: Node) -> void:
	notify_property_list_changed()
