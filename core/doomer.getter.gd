extends Node
class_name _Doomer_Getter

@onready var doomer : _Core = find_parent("_Core")

func _ready() -> void:
	pass

static func unpack(things : Array):
	var unpacked_things = []
	for thing in things:
		if thing is _Doomer_Getter:
			unpacked_things.append(thing.grab())
		else:
			unpacked_things.append(thing)
	return unpacked_things


static func flatten(things : Array):
	var flattened_things = []
	for thing in things:
		# TODO:Refactor to also handle whole-depth flattening
		if thing is Array:
			flattened_things.append_array(thing)
		else:
			flattened_things.append(thing)
	return flattened_things

static func unpack_and_flatten(things : Array):
	return flatten(unpack(things))
""" 
func world_map_scene():
	return doomer.find_child("World Map Scene")
"""
