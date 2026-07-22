### Event 1-1 ###
extends _RPGM_Script
var slide_duration = 1.0

func _on_viewport_start():
	await get_rpgm().get_lambdas().show_messages(["Map started.."])
	get_parent().queue_free()
