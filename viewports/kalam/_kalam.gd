extends _Core_Viewport
class_name _Kalam

signal finished

@export_category("Scripts")
@export var player_turn : Script


# QNA = {"The act of rising highly.", ["Jalaa", "Daana"], 0, "Wa jalaa al 2awwalo lahu, 3ada lroshdihi kal3'athi mamdanu", "al kindi"}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	camera = %Camera2D as Camera2D
	await _Starter_Turn.new().start(self)


func _on_viewport_start():
	super()
