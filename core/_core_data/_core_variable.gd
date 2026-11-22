extends Resource
class_name _Core_Variable


@export var name = "_dummy"
@export_enum("String", "Number") var type = "Number"
@export var value = 3.14

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
