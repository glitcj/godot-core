@tool
extends _Core_Viewport
class_name _RPGM


signal finished


func get_core(): return find_parent("_Core") as _Core
func get_map(): return find_child("_RPGM_Map") as _RPGM_Map
func get_player(): return find_child("_RPGM_Map").find_child("Player") as _RPGM_Player
func get_camera(): return get_map().find_child("Camera2D") as Camera2D
func get_lambdas(): return find_child("_RPGM_Lambdas") as _RPGM_Lambdas
func get_log(): return find_child("_Core_Log") as _Core_Log

func _ready() -> void:
	super()
	get_core().get_log().add_log(func tester(): return "is_active: %s" % is_active)

func _on_viewport_start():
	super()

func _on_viewport_finish():
	super()

func _activate():
	super()
	await get_tree().process_frame
	find_child("Player").is_active = true
	

func _deactivate():
	find_child("Player").is_active = false
	super()


# CLAUDE: save/load P2+P4 (see other/docs/md/save-load-plan.md) — battery-save
# style: collect a small explicit state dict, JSON it to user://, and on load
# apply it back onto the live world. Vector2is stored as [x, y] arrays
# (JSON-safe); everything comes back as floats, hence the int() casts.
const SAVE_VERSION = 1

func _save_path(slot: int) -> String: return "user://rpgm_save_%d.json" % slot

func collect_state() -> Dictionary:
	var events := {}
	for e : _RPGM_Event in get_map().find_children("*", "_RPGM_Event"):
		events[String(e.name)] = e.state
	var p : _RPGM_Player = get_player()
	return {
		"version": SAVE_VERSION,
		"variables": _RPGM_Variables.variables.duplicate(),
		"events": events,
		"player": {
			"map_position": [p.map_position.x, p.map_position.y],
			"facing": [p.facing.x, p.facing.y],
		},
	}

func apply_state(state: Dictionary) -> void:
	_RPGM_Variables.variables = state.get("variables", {}).duplicate()
	var events : Dictionary = state.get("events", {})
	for e : _RPGM_Event in get_map().find_children("*", "_RPGM_Event"):
		if events.has(String(e.name)):
			# CLAUDE: the state setter handles presentation (incl. Removed)
			e.state = int(events[String(e.name)]) as _RPGM_Event.EventState
	var p : _RPGM_Player = get_player()
	var player_state : Dictionary = state.get("player", {})
	if player_state.has("map_position"):
		p.teleport(Vector2i(int(player_state.map_position[0]), int(player_state.map_position[1])))
	if player_state.has("facing"):
		p.face(Vector2i(int(player_state.facing[0]), int(player_state.facing[1])))
	p.direction = Vector2i.ZERO
	p.next_direction = Vector2i.ZERO

# CLAUDE: the "safe moment" rule — saving is only allowed while nothing
# blocking is in flight, which is what lets us never serialize tweens or
# coroutines. Only interrupt_player scripts count (same definition of
# "blocked" as _RPGM_Player._process): ghost patrols are while-true loops
# whose is_running() is permanently true, so checking every script made
# saving impossible
func can_save() -> bool:
	if not is_active: return false
	var p : _RPGM_Player = get_player()
	if p == null or p.is_moving: return false
	for s : _RPGM_Script in get_map().scripts_currently_on_map():
		if s.interrupt_player and s.is_running(): return false
	return true

func save_game(slot := 1) -> bool:
	if not can_save(): return false
	var f := FileAccess.open(_save_path(slot), FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(collect_state(), "\t"))
	f.close()
	return true

func load_game(slot := 1) -> bool:
	if not FileAccess.file_exists(_save_path(slot)): return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(_save_path(slot)))
	if parsed == null or not parsed is Dictionary: return false
	apply_state(parsed)
	return true

# CLAUDE: debug-only test keys (F5 save / F9 load); input callbacks don't run
# while the viewport is suspended, so only the active scene responds
func _unhandled_key_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not OS.is_debug_build(): return
	if not (event is InputEventKey and event.pressed and not event.echo): return
	match event.keycode:
		KEY_F5: print("save_game: ", save_game())
		KEY_F9: print("load_game: ", load_game())
