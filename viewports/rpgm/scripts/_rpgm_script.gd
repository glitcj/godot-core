@icon("res://addons/at-icons/control/anchor.svg")
# CLAUDE: extends _RPGM_Node — common get_*() lazy cached getters inherited;
# only the parent-scoped lookups are overridden below
extends _RPGM_Node
class_name _RPGM_Script

signal actioned_within_area
signal frame_started
signal area_entered_by_player
signal actioned

@export var interrupt_player := false
@export var is_collision := false
@export var is_active = true
func _is_active() -> bool: return true

# CLAUDE: avoids emitting frame_started every frame for scripts that don't override _on_frame
var _has_on_frame_override: bool = false

# CLAUDE: a script's area/mover live on its parent event, not on itself —
# override the base class's self-scoped lookups
func get_area() -> Area2D: return _cached(&"area", func(): return get_parent().find_child("Area2D")) as Area2D
func get_mover() -> _RPGM_Mover: return mover

func get_event(): return get_parent() as _RPGM_Event

var last_distnace_from_player : Vector2 = Vector2.ZERO
var current_distnace_from_player : Vector2 = Vector2.ZERO

# CLAUDE: lazy properties instead of vars filled by _get_components — subclasses
# access these bare (e.g. `mover.walk(...)` in ghost, `portrait.animation_player`
# in talker), so they stay properties rather than becoming get_*() functions
var parent : Object:
	get:
		if not is_instance_valid(parent): parent = get_parent()
		return parent
var mover : _RPGM_Mover:
	get:
		# CLAUDE: the parent event IS the mover now (mixin refactor)
		if not is_instance_valid(mover): mover = get_parent() as _RPGM_Mover
		return mover
var portrait : _RPGM_Portrait:
	get:
		if not is_instance_valid(portrait): portrait = get_parent().find_child("_RPGM_Portrait")
		return portrait

var trigger_is_running : Dictionary = {}

func _ready():
	# CLAUDE: _get_components removed — node refs now resolve lazily in their getters
	_detect_on_frame_override()
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
	# get_rpgm().started.connect(_wrapped_callable.bind(_on_viewport_start))
	# get_rpgm().started.connect(_wrapped_callable.bind(_on_viewport_start))
	get_rpgm().activated.connect(_wrapped_callable.bind(_on_viewport_start))
	
	if get_area(): get_area().body_entered.connect(_check_area_signals)
	area_entered_by_player.connect(_wrapped_callable.bind(_on_area_entered))
	
func _detect_on_frame_override():
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

# var is_active = false

func _update_active_state():
	# this pattern is fragile ? to process_frame awaits and skips
	# probably no
	if (last_is_active and not _is_active()): _deactivate()
	if (not last_is_active and _is_active()): _activate()
	

	last_is_active = _is_active()

func _process(_delta: float):
	if not get_rpgm() or not get_player():
		return
		
	if not get_rpgm().is_active:
		return
	
	
	
	_update_active_state()
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

func _activate():
	visible = true
	is_active = true
	get_map().mark_collision_dirty()
	get_event().update_active_scripts()

func _deactivate():
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
	# CLAUDE: the player IS the mover now (mixin refactor)
	var player_position = get_player().map_position as Vector2i
	var direction = Vector2(player_position - get_mover().map_position).normalized()
	assert(direction.abs().x + direction.abs().y == 1) # make sure direction is in udlr
	return Vector2i(direction)
