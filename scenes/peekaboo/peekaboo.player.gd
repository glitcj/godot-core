extends Node2D
class_name _RPGM_Player

# func is_collision(): return true
var is_collision = true

var is_active = false:
	set(v):
		if get_RPGM() and not get_RPGM().is_active:
			return
		is_active = v

@onready var mover = find_child("_RPGM_Mover") as _RPGM_Mover
@onready var map = find_parent("_RPGM_Map") as _RPGM_Map

func get_RPGM(): return find_parent("_RPGM") as _RPGM
func get_log(): return get_RPGM().get_log() as _Core_Log
func get_portrait(): return find_child("_RPGM_Portrait") as _RPGM_Portrait
func get_mover(): return find_child("_RPGM_Mover") as _RPGM_Mover



var direction = Vector2i.ZERO as Vector2i
var next_direction = Vector2i.ZERO:
	set(v):
		next_direction = v
		
var input_just_pressed = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_log()


func get_log_header(): return "


(%.2f, %.2f)
Vector Log:" % [mover.map_position.x, mover.map_position.y]
func get_direction(): return Vector2(direction) as Vector2
func get_next_direction(): return Vector2(next_direction) as Vector2

func setup_log():
	get_log().add_log(get_log_header)
	get_log().add_log(get_direction)
	get_log().add_log(get_next_direction)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not get_RPGM().is_active:
		return
		
	is_active = true	
	for script : _RPGM_Script in get_RPGM().get_map().scripts_currently_on_map():
		if script.is_running() and script.interrupt_player:
			is_active = false
			
	_process_input()
	_process_movement()

# func _physics_process(delta: float) -> void:
func _process_movement() -> void:
	if not is_active:
		return
		
	if mover.is_moving:
		return
	
	if next_direction != direction:
		# await get_tree().physics_frame # Allow time for future position collision physics
		await get_tree().process_frame # Allow time for future position collision physics
		if not mover.tile_has_collision(mover.map_position + next_direction):
			direction = next_direction
				

	print(mover.map_position, direction, mover.map_position + direction)
	if mover.tile_has_collision(mover.map_position + direction):
		direction = Vector2i.ZERO
		return
	
	if direction != Vector2i.ZERO:
		# await mover.move(direction)
		await mover.move(direction)
	
func _valid_direction_is_pressed():
	for d in ["ui_up", "ui_down", "ui_left", "ui_right"]:
		if Input.is_action_just_pressed(d):
			return true
	return false
	
func _process_input():# _on_input():
	if Input.is_action_just_pressed("ui_select"):
		_Core_Tweener.new().highlight(self)
		
	if _valid_direction_is_pressed():
		next_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		next_direction = Vector2i(next_direction/next_direction.abs())
		mover.face(next_direction)

	if Input.is_action_just_pressed("ui_accept"):
		await stop()

func stop():
	if mover.is_moving:
		await mover.finished_movement
	await get_tree().process_frame
	direction = Vector2i.ZERO
	next_direction = Vector2i.ZERO
