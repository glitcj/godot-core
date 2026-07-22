extends Node2D
class_name _RPGM_Script

signal actioned_within_area
signal frame_started
signal area_entered_by_player
signal actioned

@export var interrupt_player := false
@export var is_collision := false



var is_active = false
func _is_active() -> bool: return true

# CLAUDE: cached node references — populated once at ready via _get_components
# replaces repeated find_parent/find_child calls in hot paths
var _rpgm: _RPGM
var _map: _RPGM_Map
var _player: _RPGM_Player
var _area: Area2D

# CLAUDE: avoids emitting frame_started every frame for scripts that don't override _on_frame
var _has_on_frame_override: bool = false

func get_core(): return find_parent("_Core") as _Core  # infrequent, leave as-is
func get_rpgm(): return _rpgm
func get_map(): return _map
func get_player(): return _player
func get_lambdas(): return get_map().get_lambdas() as _RPGM_Lambdas

func get_variables(): return _RPGM_Variables
func get_area(): return _area
func get_mover(): return mover  # CLAUDE: already cached in _get_components
func get_portrait(): return find_child("_RPGM_Portrait") as _RPGM_Portrait

func get_event(): return get_parent() as _RPGM_Event

var last_distnace_from_player : Vector2 = Vector2.ZERO
var current_distnace_from_player : Vector2 = Vector2.ZERO

# TODO: replace with getters
var parent : Object
var mover : _RPGM_Mover
var portrait : _RPGM_Portrait
var scene_just_started := true

var trigger_is_running : Dictionary = {}

func _ready():
	_get_components.call_deferred()
	bind_triggers.call_deferred()
	await get_tree().process_frame
	
func bind_triggers():
	var trigger_callables = [
		_on_within_range, _on_viewport_start, 
		_on_action_within_area,
		_on_frame, _on_area_entered
		]
	for c : Callable in trigger_callables:
		trigger_is_running[c.get_method()] = false
	
	
	actioned.connect(_wrapped_callable.bind(_on_action))
	actioned_within_area.connect(_wrapped_callable.bind(_on_action_within_area))
	frame_started.connect(_wrapped_callable.bind(_on_frame))
	get_rpgm().started.connect(_wrapped_callable.bind(_on_viewport_start))
	
	if get_area(): get_area().body_entered.connect(_check_area_signals)
	area_entered_by_player.connect(_wrapped_callable.bind(_on_area_entered))
	




func _get_components():
	parent = get_parent()
	# CLAUDE: cache all node refs here to avoid repeated find_parent/find_child in per-frame calls
	_rpgm = find_parent("_RPGM")
	_map = find_parent("_RPGM_Map")
	if _map:
		_player = _map.find_child("Player")
	if parent.find_children("*", "_RPGM_Mover").size() > 0:
		mover = parent.find_child("_RPGM_Mover")
	if parent.find_children("*", "_RPGM_Portrait").size() > 0:
		portrait = parent.find_child("_RPGM_Portrait")
	_area = parent.find_child("Area2D")
	
	# CLAUDE: walk the script chain (excluding the base) to detect if any derived class overrides
	# _on_frame — uses get_script_method_list() which returns only methods defined in that specific
	# script file, so the base class's no-op definition does not produce a false positive
	var s := get_script() as Script
	while s and s != _RPGM_Script:
		for m: Dictionary in s.get_script_method_list():
			if m["name"] == "_on_frame":
				_has_on_frame_override = true
				break
		if _has_on_frame_override: break
		s = s.get_base_script()

var last_is_active = false

func _process(_delta: float):
	if not get_rpgm() or not get_player():
		return
		
	if not get_rpgm().is_active:
		return
	
	
	# this pattern is fragile ? to process_frame awaits and skips
	# probably no
	if (last_is_active and not _is_active()):
		_on_deactivated()
	if (not last_is_active and _is_active()):
		_on_activated()
		
		
	last_is_active = _is_active()
	
	if not _is_active(): return
		
	_log()
	# CLAUDE: only emit frame_started if the subclass actually overrides _on_frame
	if _has_on_frame_override: frame_started.emit()
	
	if Input.is_action_just_pressed("ui_accept"):
		var player_is_facing_this_event : bool = mover.map_position == get_player().get_mover().facing + get_player().get_mover().map_position
		
		var player_is_neighbouring_this_event : bool = (get_player().get_mover().map_position - get_mover().map_position).abs().length() <= 1
		if _player_is_within_event_area():
						
			if player_is_facing_this_event and get_player().is_active:
				await get_tree().process_frame # wait for input buffer to clear
				actioned_within_area.emit()

		if player_is_neighbouring_this_event and  player_is_facing_this_event and get_player().is_active:
			await get_tree().process_frame # wait for input buffer to clear
			actioned.emit()

func _check_area_signals(body: Node2D): # Add the 'body' parameter
	if body == get_player(): 
		area_entered_by_player.emit()


func _player_is_within_event_area():
	if get_area(): return get_area().overlaps_body(get_player())

func _distance_to_player() -> float:
	return (get_player().position - parent.position).length()
	
func _wrapped_callable(c: Callable):
	if c.get_method() not in trigger_is_running.keys():
		trigger_is_running[c.get_method()] = false
		
	if not _is_active():
		return
		
	if trigger_is_running[c.get_method()]:
		return
	trigger_is_running[c.get_method()] = true
	
	await c.call()
	trigger_is_running[c.get_method()] = false


func _on_viewport_start():
	pass

func _on_frame():
	pass

func _on_within_range():
	pass

func _on_action_within_area():
	pass

func _on_activated():
	visible = true
	is_active = true
	get_map().mark_collision_dirty()
	get_event().update_active_scripts()

func _on_deactivated():
	visible = false
	is_active = false
	get_map().mark_collision_dirty()
	get_event().update_active_scripts()

func _on_area_entered():
	pass

func _on_action():
	pass


func _log():
	pass

func is_running():
	return trigger_is_running.values().any(func(x): return x)

func _get_direction_to_player():
	var player_position = get_player().find_child("_RPGM_Mover").map_position as Vector2i
	var direction = Vector2(player_position - get_mover().map_position).normalized()
	assert(direction.abs().x + direction.abs().y == 1) # make sure direction is in udlr
	return Vector2i(direction)
