extends Node
class_name _Core_Variables

var koran_loader : _Core_Data
var koran : Array
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_load_koran()
	
func _load_koran():
	koran_loader = _Core_Data.new()
	koran_loader.load_quran_csv("res://assets/kooran_de_go/quran.csv")
	for row in koran_loader.quran_db.values():
		koran.append(row["ayah_ar"])
		
	# pad
	for i in range(3):
		koran.append("- - - - -")
		koran.insert(0, "- - - - -")
		






# enum Keys {l1_1_enemies_count, l2_1_enemies_count}
# static var all: Dictionary = {} # Explicitly type it


"""
static func initialise_variables():
	# Ensure the dictionary exists before looping
	if all == null:
		all = {}
		
	for k in Keys.values():
		all[k] = 0
	
	print("Peekaboo Variables: Initialized successfully.")
"""
