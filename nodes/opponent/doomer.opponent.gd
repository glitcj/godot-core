extends Node
class_name _Doomer_Opponent

enum Traits {
	call_pair, 
	call_three_of_a_kind, 
	call_straight, 
	call_flush,
	name
	}

var traits : Dictionary = {}

var resource : _Doomer_Resource_Opponent

var resource_pool := [
	preload("res://nodes/opponent/doomer.resource.opponent.a.tres"),
	preload("res://nodes/opponent/doomer.resource.opponent.b.tres"),
	preload("res://nodes/opponent/doomer.resource.opponent.c.tres"),
	preload("res://nodes/opponent/doomer.resource.opponent.d.tres"),
	preload("res://nodes/opponent/doomer.resource.opponent.e.tres"),
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	resource = resource_pool[randi() % resource_pool.size()]
	if resource:
		_set_as_resource()
	# _randomise_traits()

func _set_as_resource():
	traits["name"] = resource.name
	traits["call_pair"] = resource.call_pair
	traits["call_three_of_a_kind"] = resource.call_three_of_a_kind
	traits["call_straight"] = resource.call_straight
	traits["call_flush"] = resource.call_flush
	
	
func _randomise_traits():
	for t in Traits.keys():
		traits[t] = randi() % 10

func description():
	var text = ""
	text  += "%s: %s\n" % ["Name", traits["name"]]
	text  += "%s: %s\n" % ["Call Pair", traits["call_pair"]]
	text  += "%s: %s\n" % ["Call Straight", traits["call_straight"]]
	
	
	if false:
		for t in Traits.keys():
			text  += "%s: %s\n" % [t, traits[t]]
	return text
