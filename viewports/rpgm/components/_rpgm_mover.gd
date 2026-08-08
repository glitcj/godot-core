@tool
# CLAUDE: refactored from an optional child node into a mixin base class:
# _RPGM_Node <- _RPGM_Mover <- _RPGM_Event / _RPGM_Player. The host node IS
# the mover now — every get_parent() manipulation below became self, and the
# facing sync hacks (_editor_update, the parent type-switch in face()) are
# replaced by the facing setter's _on_facing_changed() hook that subclasses
# override. _get_event() removed (was get_parent(), meaningless on self).
extends _RPGM_Node
class_name _RPGM_Mover

signal finished_movement
enum MovementType {Linear, Random, Exponential}

var is_moving = false:
	set(value):
		is_moving = value

@export var speed = 0.5 as float
@export var type = MovementType.Linear as MovementType

# CLAUDE: merged with the old _RPGM_Event.facing var — subclasses override
# _on_facing_changed() to forward the value to their portrait(s)
@export var facing = Vector2i(1, 0) as Vector2i:
	set(value):
		facing = value
		_on_facing_changed()

func _on_facing_changed(): pass

@export var map_position: Vector2i = Vector2i(0, 0):
	set(v):
		map_position = v
		if get_map(): get_map().mark_collision_dirty()
		if Engine.is_editor_hint(): _quantise_position()


var destination : Vector2i = Vector2i(0, 0)

func get_base_layer(): return get_map().find_child("L1 Base") as TileMapLayer

@onready var base_layer = get_base_layer()

func _ready() -> void:
	await get_tree().process_frame
	# CLAUDE: mark map dirty instead of rebuilding immediately; map's _process will pick it up
	if get_map(): get_map().mark_collision_dirty()
	await get_tree().process_frame
	face(facing)


func tilemap_to_global_position(tile_position : Vector2i):
	return base_layer.to_global(base_layer.map_to_local(tile_position))

func teleport(tile_position : Vector2i):
	if not is_inside_tree(): return

	map_position = tile_position
	global_position = tilemap_to_global_position(tile_position)

func _quantise_position():
	# CLAUDE: self-checks replace the old get_parent() null/ready checks
	if not is_node_ready(): return
	global_position = tilemap_to_global_position(map_position)

func move_to_map_position(target_map_position):
	await move(target_map_position - map_position)

func face_map_position(target_map_position):
	face(target_map_position - map_position)


func move(tile_vector : Vector2i) -> _RPGM_Mover:
	while tile_has_collision(map_position + tile_vector):
		await get_tree().process_frame
	map_position = map_position + tile_vector # activates setter
	var displacement = tilemap_to_global_position(map_position) - global_position

	is_moving = true
	await displace(displacement)
	is_moving = false

	return self


func walk_v1(tile_vector : Vector2i, face_direction = true) -> _RPGM_Mover:
	face(tile_vector)
	await move(tile_vector)
	return self

# var state = State.Idle
func _process(delta: float) -> void: pass
	# if destination != map_position: state = State.Moving
	# else: state = State.Idle


# enum State {Moving, Idle, Walking}
func walk(_destination_diff : Vector2i, face_direction = true):
	assert(_destination_diff.x == 0 or _destination_diff.y == 0)
	destination = _destination_diff + map_position

	if face_direction: face(_destination_diff)

	var next_movement_vector : Vector2i
	while destination != map_position:
		next_movement_vector = Vector2i(_destination_diff/_destination_diff.length())

		await move(next_movement_vector)

func face(tile_vector : Vector2i):
	# CLAUDE: the setter's _on_facing_changed() hook now propagates to
	# portraits — the parent type-switch and dead debug print are gone
	var normalised_vector = Vector2(tile_vector).normalized()
	facing = Vector2i(normalised_vector)
	return self


func displace(displacement : Vector2):
	var tween = create_tween()
	if type == MovementType.Exponential:
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.tween_property(self, "global_position", global_position + displacement, 1/speed).finished

	finished_movement.emit()

func tile_has_collision(tile_pos: Vector2i) -> bool:
	for layer : TileMapLayer in get_map().layers:
		var tile_data = layer.get_cell_tile_data(tile_pos)

		if tile_data == null:
			continue

		# if tile_data.get_collision_polygons_count(0) > 0:
		# 	return true
		# CLAUDE: only the converted .tres tilesets define the "rpgm-collision"
		# custom data layer — get_custom_data errors (not null) on tilesets
		# without it, so skip those layers
		if layer.tile_set.get_custom_data_layer_by_name("rpgm-collision") == -1:
			continue
		if tile_data.get_custom_data("rpgm-collision") == 1:
			return true
	if tile_has_rpgm_collision(tile_pos):
		return true
	return false

func tile_has_rpgm_collision(position: Vector2i) -> bool:
	# CLAUDE: reads from map-owned collision list — static var removed when ownership moved to _RPGM_Map
	var map : _RPGM_Map = get_map()
	if map == null: return false
	return map.tiles_with_rpgm_collision.has(position)

# Refactor _Mover
# Refactor _Map

# Refactor common events ? have event root extend script directly ?
# No have it extend _RPGM_Event and simple var exports and setters as a built in script in the event root
# Setters set the vars of component children for easy tree access
# And add common script as a components
# And saved as e.g. _common_event_teleport.tscn

# Refactor rooms ? npcs as children of rooms ?
