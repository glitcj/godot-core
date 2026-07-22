### Event 2-1 ###
extends _RPGM_Script

var slide_duration = 1.0


func _on_viewport_start():
	pass


func _on_frame():
	if get_variables().l2_enemies_count == 2:
		await get_rpgm().get_lambdas().show_messages(["NPC: You got them !", "NPC: Go to the next location.."])
		get_lambdas().transport_player(get_map().find_child("_player_position_5_1"))
		get_lambdas().transport_camera(get_map().find_child("_camera_position_5_1"))
		parent.queue_free()
