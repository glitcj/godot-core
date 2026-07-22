extends CharacterBody3D
class_name _DGM_Player

var camera_rotation_sensitivity = 0.02
var speed = 10.0 
var is_active = false:
	set(value):
		is_active = value
		_on_is_active_changed()

func _on_is_active_changed():
	%CollisionShape3D.disabled = true if not is_active else false

func _get_viewport(): return find_parent("_DGM") as _DGM

func _ready() -> void:
	pass 

func _process_muted_input(): 
	if Input.is_action_just_pressed("ui_accept"):
		%_DGM_Gun.fire()
		
var vector_pointing_to_camera_right : Vector3
var vector_pointing_to_camera_forward : Vector3

func _process_echoed_input():
	if Input.is_action_just_pressed("ui_select"):
		speed = 100. if speed == 10. else 10.

func _get_camera_basis():
	# var cam_basis = %Camera3D.global_transform.basis as Basis
	var cam_basis = %Camera3D.global_transform.basis as Basis
	vector_pointing_to_camera_right   =  cam_basis.x 
	vector_pointing_to_camera_forward = -cam_basis.z 
	vector_pointing_to_camera_forward.y = 0.
	vector_pointing_to_camera_forward = vector_pointing_to_camera_forward.normalized()
	
func _process_physics_input():
	if not is_active: return
	var direction_input = Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")
	var wasd_input = Input.get_vector("ui_a", "ui_d", "ui_s", "ui_w")
	_get_camera_basis()
	
	# Define a temporary move direction vector
	var move_direction = Vector3.ZERO
	
	rotation += Vector3(direction_input.y, -direction_input.x, 0.) * camera_rotation_sensitivity
	move_direction = (vector_pointing_to_camera_right * wasd_input.x + vector_pointing_to_camera_forward * wasd_input.y)

	# Assign to the native velocity property instead of position
	velocity = move_direction * speed

func _process_input() -> void:
	if not is_active: return
	_process_echoed_input()
	_process_muted_input()

# _process handles cosmetic changes like meshes, shaders, and visual timers
func _process(delta: float) -> void:
	_process_input()
	
# _physics_process handles all physical movements and updates physics bodies
func _physics_process(delta: float) -> void:
	_process_physics_input() # Run inputs on the physics tick
	
	# This function executes the movement loop and calculates collisions automatically
	move_and_slide() 
