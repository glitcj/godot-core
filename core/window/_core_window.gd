extends Node2D
class_name _Core_Window

signal finished

@onready var doomer : _Core = find_parent("_Core")
@onready var label : Label = find_child("Message Label")

var history : Array = []
var full_message_log : Array = []

var is_active = false

var message_queue = []
var processed_messages = []

var message : String:
	set(value):

		message = value
		
var visible_message : String:
	set(value):
		label.text = value
		visible_message = value
		
var full_log

func _process(delta: float) -> void:
	_process_input()

func add_line(s : String):
	label.text = "\n".join([label.text, s])

func _update_label_as_message():
	label.text = message
	
func _update_label_as_log():
	full_message_log.append(message)
	label.text = "\n".join(full_message_log.slice(-1 * min(3, full_message_log.size()), full_message_log.size()))
	
func start(message_queue_ : Array):
	message_queue = message_queue_
	is_active = true
	_show_next_message()
	await _Core_Tweener.new().slide_in(self)

func _show_current_message(m):
	message = m
	visible_message = message


func _show_next_message():
	is_active = false
	
	if message_queue == [] and visible:
		await _Core_Tweener.new().slide_out(self)
		finished.emit()
		queue_free.call_deferred()
		return
		
	var popped_message = message_queue.pop_front()
	print(popped_message)
	await _show_current_message(popped_message)
	processed_messages.append(popped_message)
	is_active = true



func _process_input():
	if not is_active:
		return
	# if is_busy:
	# 	return
		
	if Input.is_action_just_pressed("ui_accept"):
		await get_tree().process_frame
		await _show_next_message()

func show_log(m : String):
	message = m
	visible_message = message
	
func _show_latest_message():
	visible_message = message
