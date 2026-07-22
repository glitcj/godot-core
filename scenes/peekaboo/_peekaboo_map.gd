@tool
extends Node2D
class_name _RPGM_Map

@onready var player : CharacterBody2D = %Player
@onready var layers = find_children("L*", "TileMapLayer")

func get_event(_name): return find_child(_name) as _RPGM_Event
func find_event(_name): return find_child(_name) as _RPGM_Event
func get_lambdas(): return find_child("_RPGM_Lambdas") as _RPGM_Lambdas

@export_tool_button("Quantise All") var quantise_all_callable : Callable = _quantise_all
	
func _ready() -> void:
	if false: print_tree_pretty()
	Performance.add_custom_monitor("_rpgm_map/_rpgm_map_process", func(): return last_process_ms)

	
func _quantise_all():
	for mover in find_children("*", "_RPGM_Mover", true, false):
		(mover as _RPGM_Mover)._quantise_position()

func scripts_currently_on_map():
	return find_children("*", "_RPGM_Script")

# CLAUDE: collision tile list and rebuild logic moved here from _RPGM_Mover static vars
# _RPGM_Map is the correct owner — it owns the tile layers and can see all movers
var tiles_with_rpgm_collision: Array[Vector2i] = []
var collision_dirty: bool = false
var _all_collision_debugging_rects: Array[ColorRect] = []

func mark_collision_dirty() -> void:
	collision_dirty = true

var last_process_ms := 0.0
func _process(_delta: float) -> void:
	var start = Time.get_ticks_usec()
	# CLAUDE: deferred collision rebuild — at most once per frame, driven by the dirty flag
	if collision_dirty:
		_rebuild_collision_tiles()
		collision_dirty = false
	last_process_ms = (Time.get_ticks_usec() - start) / 1000.0


func _rebuild_collision_tiles() -> void:
	tiles_with_rpgm_collision = []
	var p
	for m: _RPGM_Mover in find_children("*", "_RPGM_Mover"):
		# if not (m.get_parent() is _RPGM_Player or m.get_parent() is _RPGM_Event): continue
		
		p = m.get_parent()
		
		if p is _RPGM_Player:
			pass
		elif p is _RPGM_Event:
			if not p.is_collision:
				continue
		else:
			continue
		tiles_with_rpgm_collision.append(m.map_position)
	_update_tilemap_collision_debugger()

func _update_tilemap_collision_debugger() -> void:
	# CLAUDE: debug visualisation only — skip in non-debug runtime builds
	if not OS.is_debug_build() and not Engine.is_editor_hint():
		return
	var base_layer := find_child("L1 Base") as TileMapLayer
	if base_layer == null: return
	for r: ColorRect in _all_collision_debugging_rects:
		r.queue_free()
	_all_collision_debugging_rects = []
	for tile_position: Vector2i in tiles_with_rpgm_collision:
		var rect := ColorRect.new()
		rect.color = Color.RED
		rect.size = Vector2(32, 32)
		rect.position = base_layer.map_to_local(tile_position)
		rect.z_index = 100
		base_layer.add_child(rect)
		_all_collision_debugging_rects.append(rect)
