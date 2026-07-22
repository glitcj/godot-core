extends Node2D

var gauge : float = 1.0
var height : float = 5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Line2D.set_point_position(1, Vector2(0, -height * gauge))
	
	

func restart():
	gauge = 1.0
