extends Node
class_name _Core

# Orchestrator
# This class assigns all the static objects that are cross-referenced across objects
# This include nodes, and things inside nodes.
# Static here means that the object does not change throughout the game, and a Pointer is not needed (for example containers)

var current_viewport : _Core_Viewport
# @onready var viewport_texture = %"Current Viewport TextureRect".texture
@onready var viewport_texture_rect = %"Current Viewport TextureRect"
@onready var camera = %Camera2D as Camera2D
@onready var turner : _Core_Turner = $Turner

func get_scene(_name): return find_child(_name) as _Core_Viewport
func get_callables(): return find_child("_Core_Callables") as _Core_Callables
func get_variables(): return find_child("_Core_Variables") as _Core_Variables
func get_log(): return %_Core_Log as _Core_Log


func _input(event):
	pass
	
func _process_input():
	if Input.is_action_just_pressed("ui_show_log"):
		%_Core_Log.visible = !%_Core_Log.visible
	if Input.is_action_just_pressed("ui_cancel"):
		# CLAUDE: on web, quit() only halts the engine and leaves a frozen
		# canvas — navigate back to the homepage instead. window.top covers
		# windowed mode, where the game runs inside an iframe.
		if OS.has_feature("web"):
			JavaScriptBridge.eval("(window.top || window).location.href = '/'")
		else:
			get_tree().quit()

func _process(delta: float) -> void:
	_process_input()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_boot.call_deferred()
	_log.call_deferred()

func _boot():
	change_viewport(get_scene("_Starter"))

var viewport_change_history = []
func change_viewport(viewport: _Core_Viewport):
	if current_viewport:
		await current_viewport._on_viewport_finish()
		current_viewport._suspend()
		# viewport_change_history.append(current_viewport)
		# viewport_stack.append(current_viewport)
	current_viewport = viewport
	
	%"Current Viewport TextureRect".texture = (viewport.find_child("SubViewport") as SubViewport).get_texture()
	
	current_viewport._resume()
	await current_viewport._on_viewport_start()

var viewport_stack = []

# these functions do more than just add remove child logic
# they also handle activation handover etc, so cannot be
# refactored completely into the _Core_Viewport class
func add_viewport(to_add_viewport: _Core_Viewport,  _container : Container, _scale := Vector2.ONE):	
	await current_viewport._on_viewport_finish()
	
	viewport_stack.append(current_viewport)
	current_viewport = to_add_viewport
	
	_container.add_child(current_viewport)	
	
	current_viewport._resume() # the viewport is suspended on _ready, so has to be awakened
	await current_viewport._on_viewport_start()

func remove_viewport(to_remove_viewport: _Core_Viewport):
	await to_remove_viewport._on_viewport_finish()
	to_remove_viewport._suspend()

	
	var next_viewport = viewport_stack.pop_at(0)
	
	current_viewport = next_viewport
	to_remove_viewport.get_parent().remove_child(to_remove_viewport)
	
	await current_viewport._on_viewport_start()

func test_log(): return "Test"
func _log():
	%_Core_Log.add_log(test_log)
	%_Core_Log.add_log(func fps(): return "FPS %s" % str(Engine.get_frames_per_second()))
	
func run_lambda_queue(rpgm_script : _RPGM_Script, lambda_queue : Array):
	if lambda_queue == []: return
	var processed = []
	while true:
		if lambda_queue == []: break
		var lambda = lambda_queue.pop_front() as _RPGM_Lambda
		await lambda.run(rpgm_script)
		processed.append(lambda)
		
	# i0 this way breaks bcs it means the 
	# lambda_queue already assigned to the 
	# node stays []
	# if lambda_queue == []: break
	for p in processed: lambda_queue.append(p)
