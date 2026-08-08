@tool
@icon("res://addons/at-icons/animation/box_wireframe.svg")
# CLAUDE: extends _RPGM_Mover — mover is now a mixin base class, so every
# event natively carries the movement exports (speed/type/facing/map_position)
extends _RPGM_Mover
class_name _RPGM_Event

enum EventState {A, B, C, D, E, F, G}
@export var state : EventState = EventState.A

@onready var portraits = find_children("*", "_RPGM_Portrait")

# CLAUDE: replaces the old local facing var — _RPGM_Mover's facing setter
# calls this hook; guard because the scene can apply the exported facing
# during load, before @onready has populated portraits
func _on_facing_changed():
	if portraits == null: return
	for p in portraits: if p: p.facing = Vector2(facing)

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
	# CLAUDE: run _RPGM_Mover's _ready (collision dirty + initial face) —
	# before the editor-hint return, since the old mover child ran it in the
	# editor too (both scripts are @tool)
	super()
	if Engine.is_editor_hint(): return # new
	update_active_scripts.call_deferred()
	# get_core().get_log().add_log(func(): return name + str(portraits))

func _process(delta: float):
	if Engine.is_editor_hint(): return
	
func _child_entered_tree(_node: Node) -> void:
	notify_property_list_changed()

func _child_exiting_tree(_node: Node) -> void:
	notify_property_list_changed()
