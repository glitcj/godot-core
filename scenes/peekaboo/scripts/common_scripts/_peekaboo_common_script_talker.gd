extends _RPGM_Script
class_name _RPGM_Common_Script_Talker

@export var messages : Array[String] = []

func _ready():
	super()
	interrupt_player = true
	
func _on_viewport_start():
	pass
	
func _on_entered_range():
	portrait.animation_player.play("talking")

func _on_exited_range():
	portrait.animation_player.play("idle")

func _on_action():
	await get_mover().face(_get_direction_to_player())
	await get_rpgm().get_lambdas().show_messages(messages)
