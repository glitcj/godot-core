@tool
@icon("res://addons/at-icons/mesh/sticker.svg")
extends Control
class_name _Core_TODO

@export var visible_at_runtime := true

@export_multiline var notes : String = "":
	set(value):
		if not Engine.is_editor_hint(): return
		notes = value
		# CLAUDE: null-guard — this setter runs while the scene loads, before
		# the Label child exists, which errored on every editor startup
		var label := find_child("Label") as Label
		if label: label.text = notes
		

func _ready():
	if not Engine.is_editor_hint() and not visible_at_runtime:
		visible = false
