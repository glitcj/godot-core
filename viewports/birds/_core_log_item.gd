extends MarginContainer
class_name _Core_Log_Vector

@export var to_log : Callable = func(): return:
	set(value):
		to_log = value

var vector
var _string
var scalar

@export var max_vector_length = 1. # expected maximum length
var hud_vector_length_multiplier = 300.
var hud_vector_length

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	update()
	
func update():
	if not to_log.is_valid():
		return
	if to_log.call() == null:
		return
	
	if to_log.call() is Vector2:
		%"MarginContainer Vector".visible = true
		vector = to_log.call() as Vector2
		%"Label Name".text = to_log.get_method()
		%"Label Value".text = "(%.2f, %.2f), length: %.2f" % [vector.x, vector.y, vector.length()]
		
		hud_vector_length = (1. / max_vector_length) * hud_vector_length_multiplier
		var changed_points = %"Line2D Vector".points
		changed_points[1] = vector * hud_vector_length
		%"Line2D Vector".points = changed_points

	if to_log.call() is String:
		%"MarginContainer String".visible = true
		_string = to_log.call() as String
		%"Label String".text = "%s: %s" % [to_log.get_method(), to_log.call()]
