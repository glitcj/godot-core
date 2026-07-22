extends Node2D
class_name _Core_Portrait

enum EnemySprite {default, red}

# const GHOST_MATERIAL = preload("res://scenes/peekaboo/peekaboo.shader.enemy.gdshader")


@export var sprite : EnemySprite = EnemySprite.default:
	set(v):
		%AnimatedSprite2D.animation = EnemySprite.keys()[v]
		sprite = v
		
@export var is_ghost = false:
	set(v):
		is_ghost = v
		_update_material()

@onready var animation_player : AnimationPlayer = %AnimationPlayer as AnimationPlayer



func _update_material():
	# TODO: Understand more about light masks, and shaders, light bitmasks arent simple filters
	if %AnimatedSprite2D:
		if not is_ghost:
			%AnimatedSprite2D.material = null
			%AnimatedSprite2D.light_mask = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_material()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



var _tween : Tween

func _play(frames: Array):
	if _tween: _tween.kill()
	_tween = create_tween().set_loops()
	for f in frames:
		_tween.tween_property(%AnimatedSprite2D, "frame", f, 1.0)

func face_down():  _play([0, 1, 2])
func face_right(): _play([6, 7, 8])
func face_left():  _play([3, 4, 5])
func face_up():    _play([11, 12, 13])
