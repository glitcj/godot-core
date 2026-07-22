extends _Core_Viewport
class_name _Starter



@export var next_scene : _Core_Viewport


@export_category("Scripts")
@export var player_turn : Script


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = %Camera2D as Camera2D
	await _Starter_Turn.new().start(self)


func _on_viewport_start():
	super()
