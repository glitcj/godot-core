extends Node
class_name _Doomer_Handler

signal finished_input_mode
signal input_received

enum InputMode {Inactive, Active}

var mode: InputMode = InputMode.Active
var input_tray : Key

@onready var doomer: _Core = get_parent()

# TODO: Will be extended:
# Gamepad buttons
# var button: JoyButton = JOY_BUTTON_A
# Mouse buttons
# var mouse: MouseButton = MOUSE_BUTTON_LEFT

func handle_inputs(event):
	_process_input(event)

func get_first_input_event_keycode(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode
	return null

func _process_input(event):
	var event_keycode = get_first_input_event_keycode(event)
	

	if event_keycode == null:
		return
	
	input_tray = event_keycode
	finished_input_mode.emit()
	input_received.emit()
