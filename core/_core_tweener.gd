extends RefCounted
class_name _Core_Tweener
## One-shot show/hide tweens shared by every scene.
##
## All methods are static and return the [Tween] they build, so callers choose
## how to wait:
## [codeblock]
## _Core_Tweener.fade_in(map)                          # fire and forget
## await _Core_Tweener.slide_in(label).finished        # block until done
## var tween = _Core_Tweener.slide_out(verse)          # keep it, await later
## [/codeblock]

# CLAUDE: rewritten as static methods returning the Tween — the old
# `_Core_Tweener.new()` pattern orphaned a Node per call (never in tree,
# never freed), and awaiting inside the methods hid the Tween from callers
# who wanted to compose several animations.

const DISPLACEMENT := 300.0

## Slides [param tweenee] in from [param vector] * [param displacement] away,
## fading from transparent, and leaves it visible at [param base_position].
static func slide_in(tweenee : CanvasItem, duration := 0.5, vector := Vector2(0, 1), base_position := Vector2.ZERO, displacement := DISPLACEMENT) -> Tween:
	var tween = _new_tween(tweenee)
	tween.tween_callback(func():
		# CLAUDE: start offset is now relative to base_position (was the old
		# "CHANGE ZERO VECTOR TO BASE POSITION" TODO; identical for the
		# default Vector2.ZERO every current caller uses)
		tweenee.position = base_position + vector * displacement
		tweenee.modulate = Color(1, 1, 1, 0)
		tweenee.visible = true)
	tween.tween_property(tweenee, "position", base_position, duration)
	tween.parallel().tween_property(tweenee, "modulate", Color.WHITE, duration)
	return tween

## Slides [param tweenee] out towards [param vector] * [param displacement],
## fading to transparent, then hides it and restores nothing — its position
## stays displaced until the next [method slide_in].
static func slide_out(tweenee : CanvasItem, duration := 0.5, vector := Vector2(0, 1), displacement := DISPLACEMENT) -> Tween:
	var tween = _new_tween(tweenee)
	var base_position = tweenee.position
	tween.tween_callback(func():
		tweenee.position = base_position
		tweenee.modulate = Color.WHITE)
	tween.tween_property(tweenee, "position", base_position + vector * displacement, duration)
	tween.parallel().tween_property(tweenee, "modulate", Color(1, 1, 1, 0), duration)
	tween.tween_callback(func(): tweenee.visible = false)
	return tween

## Fades [param tweenee] out — to black when [param into_black], otherwise
## to transparent.
static func fade_out(tweenee : CanvasItem, duration := 1., into_black := true) -> Tween:
	var tween = _new_tween(tweenee)
	tween.tween_callback(func(): tweenee.modulate = Color.WHITE)
	tween.tween_property(tweenee, "modulate", Color.BLACK if into_black else Color(1, 1, 1, 0), duration)
	return tween

## Fades [param tweenee] in from black — to full colour when
## [param into_black], otherwise to transparent.
static func fade_in(tweenee : CanvasItem, duration := 1., into_black := true) -> Tween:
	var tween = _new_tween(tweenee)
	tween.tween_callback(func(): tweenee.modulate = Color.BLACK)
	tween.tween_property(tweenee, "modulate", Color.WHITE if into_black else Color(1, 1, 1, 0), duration)
	return tween

## Pulses an [_RPGM_Mover]'s tint and scale while briefly doubling its speed.
static func highlight(tweenee : Node2D) -> Tween:
	var tween = _new_tween(tweenee)
	var duration = .5

	tween.tween_callback(func():
		tweenee.position = Vector2.ZERO
		tweenee.modulate = Color.WHITE)

	var base_scale = tweenee.scale as Vector2
	var mover = tweenee as _RPGM_Mover
	var base_speed = mover.speed

	tween.tween_property(tweenee, "modulate", Color(1, 0, 1, 1), duration)
	tween.parallel().tween_property(tweenee, "scale", base_scale * 1.2, duration)
	tween.parallel().tween_property(mover, "speed", base_speed * 2, 0.1)

	tween.tween_property(tweenee, "modulate", Color.WHITE, duration)
	tween.parallel().tween_property(tweenee, "scale", base_scale, duration)
	tween.parallel().tween_property(mover, "speed", base_speed, 0.1)
	return tween

static func _new_tween(tweenee : Node) -> Tween:
	return tweenee.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
