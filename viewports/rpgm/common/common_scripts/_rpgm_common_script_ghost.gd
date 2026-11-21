extends _RPGM_Script
class_name _RPGM_Common_Script_Ghost

@export var movement : Array[Vector2i] = []

func _on_viewport_start():
	if movement == []:
		return
	
	await get_tree().process_frame
	var vector : Vector2i
	while true:
		vector = movement.pop_front()
		movement.append(vector)	
		await mover.walk(vector)
		
		await get_tree().create_timer(1).timeout
		pass
