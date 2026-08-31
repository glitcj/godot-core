extends _Core_Viewport
class_name _Scroller

signal finished(selection)

# CLAUDE: verses are spawned in _ready from _verse.tscn (extracted from five
# duplicated node blocks embedded in the scene), so total_verses_on_page is
# authoritative now instead of silently disagreeing with the scene
const VERSE_SCENE = preload("res://viewports/scroller/_verse.tscn")

@export var is_centered = false:
	set(v):
		position = Vector2(-540, -350) if v else Vector2.ZERO
		is_centered = v

@export_category("Words")
@export var words : Array[String]

# CLAUDE: slot layout is computed here now — the _scroll_position_* markers
# and the container stack that positioned them are gone from the scene.
# Scale/alpha are looked up by distance from the center slot, so the arrays
# need floor(total_verses_on_page / 2) + 1 entries. Defaults reproduce the
# old container-derived layout.
@export_category("Slots")
@export var total_verses_on_page := 5
@export var slot_center := Vector2(540, 400)
@export var slot_spacing := 343.43
@export var slot_scales : Array[float] = [1.0, 0.6, 0.2]
@export var slot_alphas : Array[float] = [1.0, 0.5882353, 0.0]

func get_variables(): return (find_parent("_Core").find_child("_Core_Variables") as _Core_Variables)
func get_core(): return find_parent("_Core") as _Core

var interrupt_scroll = true
var selection : String
var scroll_counter = 100
var current_verse_index = 1
var verses : Array[_Scroller_Verse] = []

@onready var scroll_messages = get_variables().koran as Array


func _ready() -> void:
	super()
	camera = %Camera2D as Camera2D
	for i in range(total_verses_on_page):
		var verse : _Scroller_Verse = VERSE_SCENE.instantiate()
		verse.name = "_verse_%s" % i
		verse.visible = false
		%Verses.add_child(verse)
		verses.append(verse)

# `verses` is a ring: after every scroll it is rotated so that verses[i] is
# always the verse currently sitting on slot i.

func _center_slot() -> int:
	return floori(total_verses_on_page / 2.0)

func _slot_position(slot : int) -> Vector2:
	return slot_center + Vector2(0, (slot - _center_slot()) * slot_spacing)

func _slot_scale(slot : int) -> Vector2:
	return Vector2.ONE * slot_scales[abs(slot - _center_slot())]

func _slot_modulate(slot : int) -> Color:
	return Color(1, 1, 1, slot_alphas[abs(slot - _center_slot())])


func _on_viewport_start():
	super()
	await get_tree().process_frame

	interrupt_scroll = true
	await _initiate_visible_labels()
	interrupt_scroll = false

func _on_viewport_finish():
	var tweener : Tween
	for i in range(total_verses_on_page):
		if i == _center_slot():
			# TODO: Replace with shader
			tweener = _Core_Tweener.slide_out(verses[i], .5, Vector2i(0, -1))
		else:
			verses[i].visible = false
	await tweener.finished
	super()

func _initiate_visible_labels():
	for i in range(total_verses_on_page):
		var verse = verses[i]
		verse.index = current_verse_index + i
		verse.text = scroll_messages[current_verse_index + i]
		verse.position = _slot_position(i)
		verse.modulate = _slot_modulate(i)
		verse.scale = _slot_scale(i)
		verse.visible = false

	var tweener : Tween
	for i in range(total_verses_on_page):
		# CLAUDE: slot passed as base_position — verses used to live inside
		# the marker containers, where sliding back to local zero landed on
		# the slot for free; under a common parent the slot must be explicit
		tweener = _Core_Tweener.slide_in(verses[i], 1.0, Vector2(0, 1), _slot_position(i))
	await tweener.finished


# CLAUDE: merged _scroll_up/_scroll_down — they were mirror images differing
# only in sign. direction is +1 for the next verse, -1 for the previous.
func _scroll(direction : int):
	if direction > 0 and verses[-1].index == scroll_messages.size() - 1:
		return
	if direction < 0 and verses[0].index == 1:
		return

	interrupt_scroll = true
	# the verse leaving the visible window; it wraps around and gets recycled
	var wrapping_verse : _Scroller_Verse = verses[0] if direction > 0 else verses[-1]
	var tweener : Tween

	for i in range(total_verses_on_page):
		var verse = verses[i]
		var target_slot = (i - direction + total_verses_on_page) % total_verses_on_page

		tweener = verse.create_tween()
		if verse == wrapping_verse:
			tweener.tween_callback(func(): verse.visible = false)

		tweener.tween_property(verse, "position", _slot_position(target_slot), .25)
		tweener.parallel().tween_property(verse, "modulate", _slot_modulate(target_slot), .25)
		tweener.parallel().tween_property(verse, "scale", _slot_scale(target_slot), .25)

	await tweener.finished
	wrapping_verse.index = verses[-1].index + 1 if direction > 0 else verses[0].index - 1
	wrapping_verse.text = scroll_messages[wrapping_verse.index]
	for _verse in verses:
		_verse.visible = true
	interrupt_scroll = false

	if direction > 0:
		verses.append(verses.pop_front())
	else:
		verses.insert(0, verses.pop_back())
	current_verse_index += direction


func _input(event: InputEvent) -> void:
	if not is_active: return
	if not event is InputEventKey: return
	if not (event.pressed and not event.echo): return
	if interrupt_scroll: return

	match (event as InputEventKey).keycode:
		KEY_RIGHT:

			if scroll_counter > 0:
				scroll_counter = scroll_counter - 1
				await _scroll(1)
			else:
				finished.emit("_word_0")

		KEY_LEFT:
			if scroll_counter > 0:
				scroll_counter = scroll_counter - 1
				await _scroll(-1)
			else:
				finished.emit("_word_1")

		KEY_ENTER:
			finished.emit("_word_1")

		_:
			pass

func _reset_scroller():
	pass
