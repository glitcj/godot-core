extends Node
class_name _Core_Data

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


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
	
