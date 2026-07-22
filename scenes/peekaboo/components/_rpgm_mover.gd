@tool
extends Node
class_name _RPGM_Mover

signal finished_movement
enum MovementType {Linear, Random, Exponential}

var is_moving = false:
	set(value):
		is_moving = value

@export var speed = 0.5 as float
@export var type = MovementType.Linear as MovementType

@export var facing = Vector2i(1, 0) as Vector2i


func _editor_update():
	if "facing" in  get_parent():
		facing = get_parent().facing
	face(facing)
	
@export var map_position: Vector2i = Vector2i(0, 0):
	set(v):
		map_position = v
		# CLAUDE: dirty flag now lives on _RPGM_Map — it owns collision state and drives rebuild in its _process
		if get_map(): get_map().mark_collision_dirty()
		if Engine.is_editor_hint(): _quantise_position()
		

var destination : Vector2i = Vector2i(0, 0)

func get_map(): return find_parent("_RPGM_Map") as _RPGM_Map
func get_base_layer(): return get_map().find_child("L1 Base") as TileMapLayer
func _get_event(): return get_parent() as _RPGM_Event 

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
	get_parent().global_position = tilemap_to_global_position(tile_position)
	
func _quantise_position():
	get_parent().global_position = tilemap_to_global_position(map_position)

func move_to_map_position(target_map_position):
	await move(target_map_position - map_position)

func face_map_position(target_map_position):
	face(target_map_position - map_position)
	

func move(tile_vector : Vector2i) -> _RPGM_Mover:
	
	
	while tile_has_collision(map_position + tile_vector):
		await get_tree().process_frame
	map_position = map_position + tile_vector # activates setter
	var displacement = tilemap_to_global_position(map_position) - get_parent().global_position 
	
	is_moving = true
	await displace(displacement)
	is_moving = false
	
	return self


func walk_v1(tile_vector : Vector2i, face_direction = true) -> _RPGM_Mover:
	face(tile_vector)
	await move(tile_vector)
	return self

# var state = State.Idle
func _process(delta: float) -> void:
	pass
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
	var normalised_vector = Vector2(tile_vector).normalized()
	facing = Vector2i(normalised_vector)
	
	
	if not (facing.length() != 1 or facing.length() != 0):
		print(facing, facing.length())	
	
	
	if get_parent() is _RPGM_Event:
		get_parent().facing = Vector2(facing)
	elif get_parent() is _RPGM_Player:
		get_parent().get_portrait().facing = facing
		
	
	
	"""
	if get_parent() is _RPGM_Event:
		for script : _RPGM_Script in get_parent().active_scripts:
			if script.get_portrait():
				script.get_portrait().facing = Vector2(facing)
	elif get_parent() is _RPGM_Player:
		(get_parent() as _RPGM_Player).get_portrait().facing = Vector2(facing)
	"""
		
	
	return self


func displace(displacement : Vector2):
	var tween = get_parent().create_tween()
	if type == MovementType.Exponential:
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.tween_property(get_parent(), "global_position", get_parent().global_position + displacement, 1/speed).finished
	
	finished_movement.emit()
	
func tile_has_collision(tile_pos: Vector2i) -> bool:
	for layer : TileMapLayer in get_map().layers:
		var tile_data = layer.get_cell_tile_data(tile_pos)
		
		if tile_data == null:
			continue
	
		if tile_data.get_collision_polygons_count(0) > 0:
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
