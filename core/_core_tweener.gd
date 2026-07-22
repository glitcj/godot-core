extends Node
class_name _Core_Tweener

var displacement = 300
var tween : Tween

func set_displacement(v):
	displacement = v
	return self

func slide_in(tweenee : Node, duration := 0.5, vector = Vector2i(0, 1), base_position : Vector2 = Vector2.ZERO):
	tween = tweenee.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	var _disaplacement = 300

	tween.tween_callback(func(): tweenee.position = vector * _disaplacement)
	tween.tween_callback(func(): tweenee.modulate = Color(1, 1, 1, 0))
	tween.tween_callback(func(): tweenee.visible = true)

	# CHANGE ZERO VECTOR TO BASE POSITION
	tween.tween_property(tweenee, "position", base_position, duration)
	tween.parallel().tween_property(tweenee, "modulate", Color(1,1,1,1), duration)
	await tween.finished

func slide_out(tweenee : Node, duration := 0.5, vector = Vector2i(0, 1)):
	tween = tweenee.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	var base_position = tweenee.position

	# CHANGE ZERO VECTOR TO BASE POSITION
	tween.tween_callback(func(): tweenee.position = base_position)
	tween.tween_callback(func(): tweenee.modulate = Color(1, 1, 1, 1))

	var _disaplacement = 300
	tween.tween_property(tweenee, "position", Vector2(Vector2(vector * _disaplacement) + base_position), duration)
	tween.parallel().tween_property(tweenee, "modulate", Color(1,1,1,0), duration)
	tween.tween_callback(func(): tweenee.visible = false)

	await tween.finished

func highlight(tweenee : Node2D):
	tween = tweenee.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	var duration = .5

	tween.tween_callback(func(): tweenee.position = Vector2(0, 0))
	tween.tween_callback(func(): tweenee.modulate = Color(1, 1, 1, 1))

	var base_scale = tweenee.scale as Vector2
	tween.set_loops(1)

	var mover = tweenee.find_child("_RPGM_Mover") as _RPGM_Mover
	var base_speed = mover.speed

	tween.tween_property(tweenee, "modulate", Color(1,0,1,1), duration)
	tween.parallel().tween_property(tweenee, "scale", base_scale * 1.2, duration)
	tween.parallel().tween_property(mover, "speed", base_speed * 2, 0.1)

	tween.tween_property(tweenee, "modulate", Color(1,1,1,1), duration)
	tween.parallel().tween_property(tweenee, "scale", base_scale, duration)
	tween.parallel().tween_property(mover, "speed", base_speed, 0.1)
