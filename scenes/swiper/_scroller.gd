extends _Core_Viewport
class_name _Scroller

signal finished(selection)

@export var is_centered = false:
	set(v):
		position = Vector2(-540, -350) if v else Vector2.ZERO
		is_centered = v

@export_category("Words")
@export var words : Array[String]

func get_variables(): return (find_parent("_Core").find_child("_Core_Variables") as _Core_Variables)
func get_core(): return find_parent("_Core") as _Core

var interrupt_scroll = true
var total_verses_on_page = 5
var selection : String
var scroll_counter = 100
var current_verse_index = 1
var verses := []

@onready var verses_initialiser = find_children("_verse_*")
@onready var scroll_messages = get_variables().koran as Array


func _on_viewport_end():	
	var tweener : _Core_Tweener
	for i in range(total_verses_on_page):
		if i == 2:
			# TODO: Replace with shader
			tweener = _Core_Tweener.new()
			tweener.slide_out(get_verses()[i], .5, Vector2i(0, -1))
		else:
			get_verses()[i].visible = false
	await tweener.tween.finished
	super()

func get_verses():
	if verses == []:
		verses = verses_initialiser.duplicate()
	return verses
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = %Camera2D as Camera2D

func _initiate_visible_labels():
	var verse : Node2D
	var scroll_position
	
	verses = []
	verses = get_verses()
		
	for i in range(total_verses_on_page):
		verse = verses[i]
		verse.index = current_verse_index + i
		verse.text = scroll_messages[current_verse_index + i]
		scroll_position = find_child("_scroll_position_%s" % i) as Node2D

		verse.global_position = scroll_position.global_position
		verse.modulate = scroll_position.applied_modulate
		verse.scale = scroll_position.applied_scale
		verse.visible = false
	
	var tweener : _Core_Tweener
	for v in verses:
		tweener = _Core_Tweener.new()
		tweener.slide_in(v, 1.0)
	await tweener.tween.finished
		
		
func _on_viewport_start():
	super()
	await get_tree().process_frame
	
	interrupt_scroll = true
	await _initiate_visible_labels()
	interrupt_scroll = false
	
func _scroll_down():
	
	if verses[0].index == 1:
		return
		
	interrupt_scroll = true
	var verse : Node2D
	var scroll_position : Node2D
	var tweener : Tween
	
	for i in range(total_verses_on_page):
		verse = verses[i] as Node2D
		scroll_position = find_child("_scroll_position_%s" % ((i + 1) % total_verses_on_page))
		
		var verse_is_at_bottom = (i == total_verses_on_page - 1)
		var verse_is_at_top = (i == 0)
			
		tweener = verse.create_tween()
		if verse_is_at_bottom:
			tweener.tween_callback(func(): verse.visible = false)
		
		tweener.tween_property(verse, "global_position", scroll_position.global_position, .25)
		tweener.parallel().tween_property(verse, "modulate", scroll_position.applied_modulate, .25)
		tweener.parallel().tween_property(verse, "scale", scroll_position.applied_scale, .25)
	
	# scale y 800 margin position -1700
	await tweener.finished
	verse = verses[total_verses_on_page - 1]
	verse.index = verses[0].index - 1
	verse.text = scroll_messages[verse.index]
	for _verse in verses:
		_verse.visible = true
	interrupt_scroll = false
	
	verses.insert(0, verses.pop_back())
	current_verse_index -= 1
	
func _scroll_up():
	if verses[-1].index == scroll_messages.size() - 1:
		return
		
	interrupt_scroll = true
	var verse : Node2D
	var scroll_position : Node2D
	var tweener : Tween
	for i in range(total_verses_on_page):
		verse = verses[i] as Node2D
		scroll_position = find_child("_scroll_position_%s" % (range(total_verses_on_page)[(i - 1 + total_verses_on_page) % total_verses_on_page]))
		
		var verse_is_at_bottom = (i == total_verses_on_page - 1)
		var verse_is_at_top = (i == 0)
		tweener = verse.create_tween()
		
		if verse_is_at_top:
			tweener.tween_callback(func(): verse.visible = false)
		tweener.tween_property(verse, "global_position", scroll_position.global_position, .25)
		tweener.parallel().tween_property(verse, "modulate", scroll_position.applied_modulate, .25)
		tweener.parallel().tween_property(verse, "scale", scroll_position.applied_scale, .25)
		
	
	await tweener.finished
	verse = verses[0]
	verse.index = verses[-1].index + 1
	verse.text = scroll_messages[verse.index]
	for _verse in verses:
		_verse.visible = true
	interrupt_scroll = false
	
	verses.append(verses.pop_front())
	current_verse_index += 1


func _input(event: InputEvent) -> void:
	if not is_active: return
	if not event is InputEventKey: return
	if not (event.pressed and not event.echo): return
	if interrupt_scroll: return
	
	match (event as InputEventKey).keycode:
		KEY_RIGHT:
			if scroll_counter > 0:
				scroll_counter = scroll_counter - 1
				await _scroll_up()
			else:
				finished.emit("_word_0")
			
		KEY_LEFT:
			if scroll_counter > 0:
				scroll_counter = scroll_counter - 1
				await _scroll_down()
			else:
				finished.emit("_word_1")
				
		KEY_ESCAPE:
			finished.emit("_word_1")
			
		_:
			pass

func _reset_scroller():
	pass
