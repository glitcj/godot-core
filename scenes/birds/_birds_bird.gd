extends CharacterBody2D
class_name _Birds_Bird

func _get_viewport(): return find_parent("_Birds") as _Birds
func _get_hud(): return _get_viewport().get_hud()

var dead_zone_pixels = 5 # Stop jittering when withinthis many pixels

var path_movement_speed = 100

var passive_movement_speed = 2.

@export var enable_logs = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%_RPGM_Portrait.facing = Vector2(0, 1)
	_loop_timer()
	if enable_logs: _add_logs()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not _get_viewport().is_active: return
	%_passive_movement_anchor.position +=  Vector2(-1, 0) * passive_movement_speed


func move(destination: Vector2):
	var tween = get_tree().create_tween()
	tween.tween_property(%_tween_movement_anchor, "position", destination, .1)
	await tween.finished

func _log_global_position():
	return global_position
	
func _log_global_destination():
	return global_destination
	
func _add_logs():
	_get_hud().add_log(_log_global_position)
	_get_hud().add_log(_log_global_destination)

@onready var global_destination = global_position
func _loop_timer():
	await get_tree().create_timer(1.).timeout
	
	if _get_viewport().is_active:
		var possible_directions = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
		var direction = possible_directions[randi() % possible_directions.size()]
		global_destination = global_position + direction * 200
		# move(%_tween_movement_anchor.position + direction * 50)
			
	_loop_timer()

func _physics_process(delta: float) -> void:
	# target_position = global_position + %_tween_movement_anchor.position +  %_passive_movement_anchor.position
	if (global_position - global_destination).length() > dead_zone_pixels:
		velocity = (global_position - global_destination).normalized() * path_movement_speed
	else:
		velocity = Vector2.ZERO
	
	# var passive_movement =  Vector2(-1, 0) * speed
	# velocity += passive_movement
	move_and_slide()


func _on_body_entered(_node : Node):
	queue_free()

func kill():
	queue_free()
	if false:
		await get_tree().create_timer(1).timeout
		get_tree().reload_current_scene()
