extends Node
class_name _RPGM_Lambdas

@onready var core : _Core = find_parent("_Core")

func get_RPGM(): return find_parent("_RPGM") as _RPGM
func get_map(): return find_parent("_RPGM_Map") as _RPGM_Map
func get_player(): return find_parent("_RPGM_Map").find_child("Player") as _RPGM_Player
func get_camera(): return get_map().find_child("Camera2D") as Camera2D


func transport_player(player_position_node : _RPGM_Event):
	assert(player_position_node is _RPGM_Event)
	var player_mover = get_player().find_child("_RPGM_Mover") as _RPGM_Mover
	player_mover.teleport(player_position_node.get_mover().map_position)
	
func transport_camera(camera_position_node):
	assert(camera_position_node is _RPGM_Event)
	var camera_mover = get_map().find_child("_RPGM_Camera").find_child("_RPGM_Mover") as _RPGM_Mover
	camera_mover.teleport(camera_position_node.get_mover().map_position)
	
	
	
func move_event(event : _RPGM_Event, destination: Vector2i):
	event.get_mover().move(destination)
	
func attach_camera_to_player():
	get_camera().reparent(get_player())
	
func dettach_camera_from_player():
	get_camera().reparent(get_map().find_child("Camera"))
	
func move_camera(delta : Vector2i):
	var mover = get_map().find_child("_RPGM_Camera").find_child("_RPGM_Mover") as _RPGM_Mover
	await mover.move(delta)
	
func show_messages(messages: Array):
	var window = _Core_Templates.window.instantiate() as _Core_Window
	var container = get_RPGM().find_child("_canvas_bottom") as CenterContainer
	container.add_child(window)
	window.scale = Vector2(5,5)
	
	window.start(messages.duplicate())
	await window.finished
	print("window finished")
	pass

func set_base_tilemap_to_rmz_standard():
	# TODO: set tile pixel size to 48 and scale to 3.333 (159.9 pixels)
	return
	
func set_base_tilemap_to_2k3_standard():
	# TODO: set tile pixel size to 16 and scale to 10 (160 pixels)
	return
	
func set_base_tilemap_to_rmv_standard():
	# TODO: set tile pixel size to 32 and scale to 5 (160 pixels)
	return
