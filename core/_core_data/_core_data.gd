extends Resource
class_name _Core_Data


@export var variables : Array[_Core_Variable] = []

func load_cache():
	_load_koran()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # ignored for Resource ?


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
	

func load_csv(file_path: String) -> Array:
	var data = []
	
	if not FileAccess.file_exists(file_path):
		push_error("File not found: " + file_path)
		return data

	var file = FileAccess.open(file_path, FileAccess.READ)
	
	while !file.eof_reached():
		var csv_row = file.get_csv_line(",")
		
		# Ensure the row isn't just an empty string at the end of the file
		if csv_row.size() > 1 or (csv_row.size() == 1 and csv_row[0] != ""):
			data.append(csv_row)
			
	file.close()
	return data



var quran_db: Dictionary = {}

func load_quran_csv(file_path: String):
	if not FileAccess.file_exists(file_path):
		push_error("CSV file not found at: " + file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	
	# Read the first line to extract headers
	var headers = file.get_csv_line()
	
	while !file.eof_reached():
		var row = file.get_csv_line()
		
		# Skip empty or mismatched rows
		if row.size() < headers.size():
			continue
			
		var entry = {}
		
		for i in range(headers.size()):
			var key = headers[i]
			var value = row[i]
			
			# Refinement: Cast specific columns to their proper types
			match key:
				"surah_no", "ayah_no_surah", "ayah_no_quran", "ruko_no", \
				"juz_no", "manzil_no", "hizb_quarter", "total_ayah_surah", \
				"total_ayah_quran", "no_of_word_ayah":
					entry[key] = value.to_int()
					
				"sajah_ayah":
					entry[key] = value.to_lower() == "true"
					
				"list_of_words":
					# Converts "[word1,word2]" string into a GDScript Array
					entry[key] = _parse_csv_list(value)
					
				_:
					# Default to string for names and Ayah text
					entry[key] = value
		
		# Indexing by 'ayah_no_quran' as the unique ID for the database
		quran_db[entry["ayah_no_quran"]] = entry
		
	file.close()
	print("Quran Database Loaded. Total Ayahs: ", quran_db.size())

# Helper to clean the bracketed list string into an actual Array
func _parse_csv_list(list_string: String) -> Array:
	var clean = list_string.replace("[", "").replace("]", "")
	return clean.split(",")

var koran = []
func _load_koran():
	# koran_loader = _Core_DataLoader.new()
	
	# koran_loader = (find_parent("_Core") as _Core).get_data()
	
	load_quran_csv("res://assets/kooran_de_go/quran.csv")
	for row in quran_db.values():
		koran.append(row["ayah_ar"])
		
	# pad
	for i in range(3):
		koran.append("- - - - -")
		koran.insert(0, "- - - - -")
		





# CLAUDE: save/load P1 — the single source of truth for global game state is
# now this dictionary (serialized as-is by _RPGM.collect_state). The old
# static ints survive as property wrappers so every existing call site
# (get_variables().l2_enemies_count etc.) keeps working unchanged.
static var tmp_variables : Dictionary = {
	"l1_enemies_count": 0,
	"l2_enemies_count": 0,
	"l3_enemies_count": 0,
	"l4_enemies_count": 0,
}

static var l1_enemies_count : int:
	get: return tmp_variables.get("l1_enemies_count", 0)
	set(v): tmp_variables["l1_enemies_count"] = v
static var l2_enemies_count : int:
	get: return tmp_variables.get("l2_enemies_count", 0)
	set(v): tmp_variables["l2_enemies_count"] = v
static var l3_enemies_count : int:
	get: return tmp_variables.get("l3_enemies_count", 0)
	set(v): tmp_variables["l3_enemies_count"] = v
static var l4_enemies_count : int:
	get: return tmp_variables.get("l4_enemies_count", 0)
	set(v): tmp_variables["l4_enemies_count"] = v
