extends Node
class_name _Core

# Orchestrator
# This class assigns all the static objects that are cross-referenced across objects
# This include nodes, and things inside nodes.
# Static here means that the object does not change throughout the game, and a Pointer is not needed (for example containers)

var current_scene : _Core_Viewport

@onready var camera = %Camera2D as Camera2D
@onready var turner : _Core_Turner = $Turner


func get_scene(_name): return find_child(_name) as _Core_Viewport
func get_lambdas(): return find_child("_Core_Lambdas") as _Core_Lambdas
func get_variables(): return find_child("_Core_Variables") as _Core_Variables
func get_log(): return %_Core_Log as _Core_Log

func _input(event):
	pass
	
func _process_input():
	if Input.is_action_just_pressed("ui_show_log"):
		%_Core_Log.visible = !%_Core_Log.visible

func _process(delta: float) -> void:
	_process_input()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_boot.call_deferred()
	_setup_log.call_deferred()

func _boot():
	change_viewport(get_scene("_Starter"))

func change_viewport(viewport: _Core_Viewport):
	if current_scene:
		await current_scene._on_viewport_end()
	current_scene = viewport
	
	%"Current Viewport".texture = (viewport.find_child("SubViewport") as SubViewport).get_texture()
	
	await viewport._on_viewport_start()






func add_viewport(parent_viewport : _Core_Viewport, child_viewport: _Core_Viewport,  _container : Container, _scale := Vector2.ONE):
	if parent_viewport == current_scene:
		await current_scene._on_viewport_end()
	current_scene = child_viewport
	
	var wrapper_node = Node2D.new()
	wrapper_node.name = "_Wrapper_"
	wrapper_node.add_child(child_viewport)
	
	
	
	print(_container)
	pass
	# if _position != Vector2.ZERO:
	# 	wrapper_node.position = _position
	if _scale != Vector2.ZERO:
		wrapper_node.scale = _scale
		
	# parent_viewport.add_child(wrapper_node)
	_container.add_child(wrapper_node)
	await child_viewport._on_viewport_start()



func remove_viewport(parent_viewport : _Core_Viewport, child_viewport: _Core_Viewport, _container : Container):
	if child_viewport == current_scene:
		await child_viewport._on_viewport_end()
	current_scene = parent_viewport

	var wrapper_node = child_viewport.get_parent() as Node2D
	
	
	# parent_scene.remove_child(wrapper_node)
	# wrapper_node.remove_child(child_scene)
	
	_container.remove_child(wrapper_node)
	wrapper_node.remove_child(child_viewport)
	wrapper_node.queue_free()
	
	# await parent_scene._on_viewport_start()
	await parent_viewport._on_viewport_start()



func add_scene(parent_scene : _Core_Viewport, child_scene: _Core_Viewport,  _position := Vector2.ZERO, _scale := Vector2.ONE):
	if parent_scene == current_scene:
		await current_scene._on_viewport_end()
	current_scene = child_scene
	
	var wrapper_node = Node2D.new()
	wrapper_node.name = "_Wrapper_"
	wrapper_node.add_child(child_scene)
	
	
	
	print(_position)
	pass
	if _position != Vector2.ZERO:
		wrapper_node.position = _position
	if _scale != Vector2.ZERO:
		wrapper_node.scale = _scale
		
	parent_scene.add_child(wrapper_node)
	await child_scene._on_viewport_start()


func remove_scene(parent_scene : _Core_Viewport, child_scene: _Core_Viewport):
	if child_scene == current_scene:
		await child_scene._on_viewport_end()
	current_scene = parent_scene

	var wrapper_node = child_scene.get_parent() as Node2D
	parent_scene.remove_child(wrapper_node)
	wrapper_node.remove_child(child_scene)
	wrapper_node.queue_free()
	
	await parent_scene._on_viewport_start()



func test_log(): return "Test"
func _setup_log():
	%_Core_Log.add_log(test_log)
	%_Core_Log.add_log(func fps(): return "FPS %s" % str(Engine.get_frames_per_second()))
