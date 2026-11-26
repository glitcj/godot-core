@tool
extends EditorPlugin


func _input(event: InputEvent) -> void:
		var key := event as InputEventKey
		if key == null or not key.pressed or key.echo: return
