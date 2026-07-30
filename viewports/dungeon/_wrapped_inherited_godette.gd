extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var is_moving = false

# func get_animation_tree(): return find_child("AnimationTree")
var TIME = 0.0
@onready var animation_tree = find_child("AnimationTree")

func _process(delta: float) -> void:
	TIME += delta

var flip = 1
func _physics_process(delta: float) -> void:
	is_moving = int(TIME) % 10 > 5
	if is_moving:
		flip = 1 if int(TIME) % 20 > 10 else -1
		velocity = Vector3(1,0,1) * 2 * flip
		
		var target_position = global_position + velocity.normalized()
		if false: look_at(target_position, Vector3.UP)
		
		var facing = Vector2(velocity.x, velocity.z).angle() + PI # Why pi ? dummy doesnt need it
		rotation.y = rotate_toward(rotation.y, facing, .2)
	
	else:
		velocity = Vector3(0, 0, 0)
		
	
	move_and_slide()
	print(velocity, TIME)
	


# func _movement_loop():
# 	velocity = Vector3(0,0,0)
