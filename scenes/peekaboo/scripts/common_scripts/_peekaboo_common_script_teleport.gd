### _common_script_teleport ###
extends _RPGM_Script
class_name _RPGM_Common_Script_Teleport

@export var camera_position_node : Node2D
@export var player_position_node : Node2D

@export_enum("2k3", "rmv", "rmz") var standard : String

func _on_area_entered():
	await get_player().stop()
	
	assert(camera_position_node != null)
	get_lambdas().transport_camera(camera_position_node)# camera_position_node.find_child("_RPGM_Mover").map_position)
	
	assert(player_position_node != null)
	get_lambdas().transport_player(player_position_node) # player_position_node.find_child("_RPGM_Mover").map_position)
