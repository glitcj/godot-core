extends Node2D
class_name _Scroller_Verse
## A single verse label; spawned by [_Scroller] and recycled as the list
## scrolls.

# CLAUDE: extracted from a GDScript embedded in _scroller.tscn; the old
# `text` setter never stored the value, so reading it back always gave ""

@export var text : String = "":
	set(v):
		text = v
		($Label as Label).text = v

@export var index : int = 1
