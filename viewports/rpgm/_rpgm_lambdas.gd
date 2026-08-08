# CLAUDE: extends _RPGM_Node — get_rpgm/get_map/get_player now inherited
# (lazy cached); the lambdas nodes in both scenes were retyped Node -> Node2D
extends _RPGM_Node
class_name _RPGM_Lambdas

@onready var core : _Core = find_parent("_Core")

func get_camera(): return get_map().find_child("Camera2D") as Camera2D


func transport_player(player_position_node : _RPGM_Event):
	assert(player_position_node is _RPGM_Event)
	# CLAUDE: the player IS the mover now (mixin refactor)
	var player_mover = get_player() as _RPGM_Mover
	player_mover.teleport(player_position_node.get_mover().map_position)
	
func transport_camera(camera_position_node):
	assert(camera_position_node is _RPGM_Event or camera_position_node is _RPGM_Player)
	if camera_position_node is _RPGM_Event:
		(get_player().find_child("RemoteTransform2D") as RemoteTransform2D).update_position = false
		get_map().find_child("_RPGM_Camera").find_child("Camera2D").position = Vector2.ZERO
		# CLAUDE: the camera node (an _RPGM_Event) IS the mover now (mixin refactor)
		var camera_mover = get_map().find_child("_RPGM_Camera") as _RPGM_Mover
		camera_mover.teleport(camera_position_node.get_mover().map_position)
		
	if camera_position_node is _RPGM_Player:
		(get_player().find_child("RemoteTransform2D") as RemoteTransform2D).update_position = true
	
func move_event(event : _RPGM_Event, destination: Vector2i):
	event.get_mover().move(destination)
	
func attach_camera_to_player():
	get_camera().reparent(get_player())
	
func dettach_camera_from_player():
	get_camera().reparent(get_map().find_child("Camera"))
	
func move_camera(delta : Vector2i):
	# CLAUDE: the camera node (an _RPGM_Event) IS the mover now (mixin refactor)
	var mover = get_map().find_child("_RPGM_Camera") as _RPGM_Mover
	await mover.move(delta)
	
func show_messages(messages: Array, _scale = Vector2(5, 5)):
	var window = _Core_Templates.window.instantiate() as _Core_Window
	var container = get_rpgm().find_child("_canvas_bottom") as CenterContainer
	container.add_child(window)
	window.scale = _scale
	
	window.start(messages.duplicate())
	await window.finished
	
func fade_in():
	pass
	
func fade_out():
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
