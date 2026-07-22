extends CharacterBody2D
class_name _Birds_Player

func _get_viewport(): return find_parent("_Birds") as _Birds
func get_hud(): return _get_viewport().get_hud() as _Core_Log

var birds_direction = Vector2(0,0)
var player_input_direction = Vector2(0,0)
var accumulated_direction = Vector2(0,0)
var player_input_movement = Vector2(0,0)
var wind_movement = Vector2(0.2, 0)
var input_plus_passive = Vector2(0,0)

@export var max_speed = 300

func _ready() -> void:
	%_RPGM_Portrait.facing = Vector2(0,1)
	
	get_hud().add_log(_get_velocity)
	get_hud().add_log(_get_absolute_velocity)
	get_hud().add_log(get_accumulated_direction)
	get_hud().add_log(get_input_plus_passive)
	
	%"Area2D HitBox".area_entered.connect(_on_hitbox_area_entered)
	
func _process(delta : float):
	pass


func get_player_input_movement(): return player_input_movement
func _get_velocity(): return velocity / max_speed
func _get_absolute_velocity(): return  "%.2f, %.2f" % [velocity.x, velocity.y] 
func get_input_plus_passive(): return input_plus_passive
func get_accumulated_direction(): return accumulated_direction
func get_player_input_direction(): return player_input_direction

func _process_muted_input():
	if Input.is_action_pressed("ui_accept"):
		var tween = get_tree().create_tween()
		tween.tween_property(self, "accumulated_direction", Vector2(0,0), 0.5)
		if false: tween.tween_property(self, "max_speed", 300, 0.5)


	if false and Input.is_action_pressed("ui_down") and Input.is_action_pressed("ui_right"):
		var tween = get_tree().create_tween()
		tween.tween_property(self, "max_speed", max_speed + 100, 0.5)
		
		
	if true: return
	player_input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")	
	accumulated_direction += player_input_direction * .1
	accumulated_direction.x = sign(accumulated_direction.x) * min(1., abs(accumulated_direction.x))
	accumulated_direction.y = sign(accumulated_direction.y) * min(1., abs(accumulated_direction.y)) 
	
	
func _process_echoed_input():
	if false: return
	player_input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")	
	accumulated_direction += player_input_direction * .25
	accumulated_direction.x = sign(accumulated_direction.x) * min(1., abs(accumulated_direction.x))
	accumulated_direction.y = sign(accumulated_direction.y) * min(1., abs(accumulated_direction.y)) 
	
func _input(event: InputEvent) -> void:
	if not _get_viewport().is_active: return
	if not (event is InputEventKey): return
	_process_echoed_input()
	
	if not (event.pressed and not event.echo): return
	_process_muted_input()

	
func _physics_process(delta: float) -> void:
	if not _get_viewport().is_active: return
	player_input_movement = accumulated_direction
	
	if delta - floor(delta)  < 0.1:
		# _process_physics is quantized every 0.1, which makes direction change detection quirky
		pass

	var velocity_flipped_horizontally = (velocity.x  * (player_input_movement + wind_movement).x) <= 0
	if velocity_flipped_horizontally:
		(%_RPGM_Portrait.find_child("Sprite2D") as Sprite2D).flip_h = player_input_direction.x < 0
		
	input_plus_passive = accumulated_direction + wind_movement
	velocity = input_plus_passive * max_speed
	
	move_and_slide()

func _on_hitbox_area_entered(node : Node):
	(node.get_parent() as _Birds_Bird).kill()
	_get_viewport().finish()
