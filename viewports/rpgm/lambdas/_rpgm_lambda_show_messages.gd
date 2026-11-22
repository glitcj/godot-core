extends _RPGM_Lambda
class_name _RPGM_Lambda_Show_Messages

@export var messages : Array[String] = ["Empty array."]
@export var _scale : Vector2 = Vector2(5, 5)

func _init(messages_ = null, scale_ = null):
	if messages_ != null: messages.assign(messages_)	
	_scale = scale_ if scale_ != null else _scale
	
# CLAUDE: parameter widened from _RPGM_Script to _RPGM_Node (see _RPGM_Lambda)
func run(rpgm_node : _RPGM_Node):
	super(rpgm_node)
	var window = _Core_Templates.window.instantiate() as _Core_Window
	var container =  rpgm_node.get_rpgm().find_child("_canvas_bottom") as CenterContainer
	container.add_child(window)
	window.scale = _scale
	
	window.start(messages.duplicate())
	await window.finished
