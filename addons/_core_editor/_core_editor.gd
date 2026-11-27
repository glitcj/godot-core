@tool
extends Node
class_name _Core_Editor

static func play_sfx(sfx_name := "res://assets/ninja/Sounds/Game/Alert.wav"):
	var sfx_player := AudioStreamPlayer.new()
	sfx_player.stream = load(sfx_name)
	EditorInterface.get_base_control().add_child(sfx_player)
	
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)
