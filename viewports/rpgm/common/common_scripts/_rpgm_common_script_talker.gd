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
	if "messages" in get_event() and get_event().messages != []:
		# CLAUDE: _RPGM_Callables removed — the action is its own lambda, run via run_lambda
		await run_lambda(_RPGM_Lambda_Show_Messages.new(get_event().messages))
	elif messages != []:
		# CLAUDE: _RPGM_Callables removed — the action is its own lambda, run via run_lambda
		await run_lambda(_RPGM_Lambda_Show_Messages.new(messages))
