extends _Core_Viewport
class_name _DGM

# Change to _DGMCamp FPS
# Shoot incoming zombies, and recite poetry after each stage

# Add night sky
# Add night sky shader
# Add 3d fire shader 
# Add stage loop, reward is a poem shining in the sky
# Poem correlates with score
# looking up you can shoot boosters in the sky for power ups


# NOTE: Sky texture appears in the alpha = 0 channel, 
# so in the nested desert map subviewprt, Transparent BG = false



signal finished

func get_hud(): return %_Core_Log as _Core_Log

func _ready() -> void:
	camera = %Camera2D as Camera2D
	if false: print_tree_pretty()
	pass
	
func _on_viewport_start():	
	super()
	
func _on_viewport_end():
	super()
	
func finish():
	finished.emit()
