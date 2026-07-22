extends CharacterBody3D
var TIME = 0.
var is_moving = false


func _ready() -> void:
	pass

func _process(delta: float) -> void:
	TIME += delta
	
var facing
var flip
func _physics_process(delta: float) -> void:
	if int(TIME) % 10 < 5:
		velocity = Vector3.ZERO
		is_moving = false
		
	else:
		flip = -1 if int(TIME) % 20 < 10 else 1
		velocity = Vector3(1., 0. , -1.) * 2 * flip
		
		facing = Vector2(velocity.x, velocity.z)
		rotation.y = rotate_toward(rotation.y, facing.angle(), 0.2)
		
		is_moving = true
		
	move_and_slide()
