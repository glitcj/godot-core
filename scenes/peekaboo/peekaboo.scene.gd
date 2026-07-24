@tool
extends _Core_Viewport
class_name _RPGM


signal finished


func get_core(): return find_parent("_Core") as _Core
func get_map(): return find_child("_RPGM_Map") as _RPGM_Map
func get_player(): return find_child("_RPGM_Map").find_child("Player") as _RPGM_Player
func get_camera(): return get_map().find_child("Camera2D") as Camera2D
func get_lambdas(): return find_child("_RPGM_Lambdas") as _RPGM_Lambdas
func get_log(): return find_child("_Core_Log") as _Core_Log

func _ready() -> void:
	super()
	get_core().get_log().add_log(func tester(): return "is_active: %s" % is_active)

func _on_viewport_start():
	super()

func _on_viewport_finish():
	super()

func _activate():
	super()
	await get_tree().process_frame
	find_child("Player").is_active = true
	

func _deactivate():
	find_child("Player").is_active = false
	super()
