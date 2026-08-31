### _common_script_teleport ###
extends _RPGM_Script
class_name _RPGM_Common_Script_Teleport

@export var camera_position_node : Node2D
@export var player_position_node : Node2D


@export var camera_position_node_3D : Node3D
@export var player_position_node_3D : Node3D

@export_enum("2k3", "rmv", "rmz") var standard : String

func _on_area_entered():
	await get_player().stop()
	
	
	camera_position_node = get_event().camera_position_node if "camera_position_node" in get_event() else camera_position_node
	player_position_node = get_event().player_position_node if "player_position_node" in get_event() else player_position_node
	
	camera_position_node_3D = get_event().camera_position_node_3D if "camera_position_node_3D" in get_event() else camera_position_node_3D
	player_position_node_3D = get_event().player_position_node_3D if "player_position_node_3D" in get_event() else player_position_node_3D
	
	if get_core().current_viewport is _RPGM:
		if not camera_position_node == null and not player_position_node == null:
			assert(camera_position_node != null)
			get_lambdas().transport_camera(camera_position_node)# camera_position_node.find_child("_RPGM_Mover").map_position)
			
			assert(player_position_node != null)
			get_lambdas().transport_player(player_position_node) # player_position_node.find_child("_RPGM_Mover").map_position)

		elif not camera_position_node_3D == null and not player_position_node_3D == null:
			pass


	elif get_core().current_viewport is _DGM:
		if not camera_position_node == null and not player_position_node == null:
			assert(camera_position_node != null)
			get_lambdas().transport_camera(camera_position_node)# camera_position_node.find_child("_RPGM_Mover").map_position)
			
			assert(player_position_node != null)
			get_lambdas().transport_player(player_position_node) # player_position_node.find_child("_RPGM_Mover").map_position)

		elif not camera_position_node_3D == null and not player_position_node_3D == null:
			pass
			
