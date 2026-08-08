# CLAUDE: @tool because the inherited mover behavior (editor quantise on
# map_position edits, the map's Quantise All button) used to run on the @tool
# mover child — it now lives on this node, so this script must be a tool
# script too; _ready/_process gained editor-hint guards to compensate
@tool
# CLAUDE: extends _RPGM_Mover — mover is now a mixin base class, so the
# player node itself carries the movement state/logic (no child mover node)
extends _RPGM_Mover
class_name _RPGM_Player

# CLAUDE: replaces face()'s old parent type-switch — _RPGM_Mover's facing
# setter calls this hook
func _on_facing_changed():
	if get_portrait(): get_portrait().facing = Vector2(facing)

# func is_collision(): return true
var is_collision = true

var is_active = false:
	set(v):
		if get_RPGM() and not get_RPGM().is_active:
			return
		is_active = v

# CLAUDE: mover child ref removed — its members are inherited now
@onready var map = find_parent("_RPGM_Map") as _RPGM_Map


# CLAUDE: kept as alias for existing call sites; resolution now inherited
func get_RPGM(): return get_rpgm()
func get_log(): return get_core().get_log() as _Core_Log

var direction = Vector2i.ZERO as Vector2i
var next_direction = Vector2i.ZERO:
	set(v):
		next_direction = v
		
var input_just_pressed = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# CLAUDE: run _RPGM_Mover's _ready (collision dirty + initial face)
	super()
	if Engine.is_editor_hint(): return
	setup_log()


func get_direction(): return Vector2(direction) as Vector2
func get_next_direction(): return Vector2(next_direction) as Vector2

func setup_log():
	get_log().add_log(get_direction)
	get_log().add_log(get_next_direction)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
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
		
	# CLAUDE: mover.* -> inherited members (mixin refactor)
	if is_moving:
		return

	if next_direction != direction:
		# await get_tree().physics_frame # Allow time for future position collision physics
		await get_tree().process_frame # Allow time for future position collision physics
		if not tile_has_collision(map_position + next_direction):
			direction = next_direction


	print(map_position, direction, map_position + direction)
	if tile_has_collision(map_position + direction):
		direction = Vector2i.ZERO
		return

	if direction != Vector2i.ZERO:
		# await mover.move(direction)
		await move(direction)
	
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
		face(next_direction) # CLAUDE: inherited from _RPGM_Mover

	if Input.is_action_just_pressed("ui_accept"):
		await stop()

func stop():
	# CLAUDE: mover.* -> inherited members (mixin refactor)
	if is_moving:
		await finished_movement
	await get_tree().process_frame
	direction = Vector2i.ZERO
	next_direction = Vector2i.ZERO
