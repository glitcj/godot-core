@tool
extends _Core_Viewport
class_name _RPGM

func get_map(): return find_child("_RPGM_Map") as _RPGM_Map
func get_player(): return find_child("_RPGM_Map").find_child("Player") as _RPGM_Player
func get_camera(): return get_map().find_child("Camera2D") as Camera2D
func get_lambdas(): return find_child("_RPGM_Lambdas") as _RPGM_Lambdas
func get_log(): return find_child("_Core_Log") as _Core_Log

func _ready() -> void:
	pass


func _on_viewport_start():
	super()

func _on_viewport_end():
	super()

func _activate():
	find_child("Player").is_active = true

func _deactivate():
	find_child("Player").is_active = false
