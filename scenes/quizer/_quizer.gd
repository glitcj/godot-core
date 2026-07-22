extends _Core_Viewport
class_name _Quizer

@export_category("Words")
@export var words : Array[String]

signal option_selected(selection)


var correct_answer_index
var incorrect_answer_index

var selection : String

var questions_counter


var koran_loader : _Core_Data
var current_verse_index

func _on_viewport_end():
	super()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = %Camera2D as Camera2D
	
	for label : Label in find_children("*", "Label"):
		label.visible = false
	
		



func _show_questions_and_answers(current_verse_index):
		
	correct_answer_index = randi() % 2
	incorrect_answer_index = int(not correct_answer_index)


	var decoy_ayah_index = 1 + (randi() % koran_loader.quran_db.size())

	print(correct_answer_index, incorrect_answer_index, "_word_%s" % correct_answer_index, "_word_%s" % incorrect_answer_index)
	(find_child("_definition") as Label).text = koran_loader.quran_db[current_verse_index]["ayah_ar"]
	(find_child("_word_%s" % correct_answer_index) as Label).text = koran_loader.quran_db[current_verse_index + 1]["ayah_ar"]
	(find_child("_word_%s" % incorrect_answer_index) as Label).text = koran_loader.quran_db[decoy_ayah_index]["ayah_ar"]
	

	await _Core_Tweener.new().slide_in(find_child("_definition"), .5)
	await _Core_Tweener.new().slide_in(find_child("_word_0"), .5, Vector2i(-1, 0))
	await _Core_Tweener.new().slide_in(find_child("_word_1"), .5, Vector2i(1, 0))


func _on_viewport_start():
	super()
	await get_tree().process_frame



	
	questions_counter = 3
	
	koran_loader = _Core_Data.new()

	koran_loader.load_quran_csv("res://assets/kooran_de_go/quran.csv")
	
	current_verse_index = 1 + (randi() % koran_loader.quran_db.size())
	_show_questions_and_answers(current_verse_index)

func _input(event: InputEvent) -> void:
	if not is_active: return
	if not event is InputEventKey: return
	if not (event.pressed and not event.echo): return
	
	match (event as InputEventKey).keycode:
		KEY_RIGHT:
			selection = "_word_0"
			await _Core_Tweener.new().slide_out(find_child("_word_0"), .5, Vector2i(1, 0))
			await _show_decision()
			
			await _Core_Tweener.new().slide_out(find_child("_word_1"), .5, Vector2i(0, 1))
			await _Core_Tweener.new().slide_out(find_child("_definition"), .5, Vector2i(0, 1))
			
			
			if questions_counter > 0:
				current_verse_index = current_verse_index + 1
				questions_counter = questions_counter - 1
				await _show_questions_and_answers(current_verse_index)
			else:
				option_selected.emit("_word_0")

			
		KEY_LEFT:
			selection = "_word_1"
			await _Core_Tweener.new().slide_out(find_child("_word_1"), .5, Vector2i(-1, 0))
			await _show_decision()
			
			await _Core_Tweener.new().slide_out(find_child("_word_0"), .5, Vector2i(0, 1))
			await _Core_Tweener.new().slide_out(find_child("_definition"), .5, Vector2i(0, 1))
			
			if questions_counter > 0:
				current_verse_index = current_verse_index + 1
				questions_counter = questions_counter - 1
				await _show_questions_and_answers(current_verse_index)
			else:
				option_selected.emit("_word_1")
		_:
			pass


func _show_decision():
	if selection == "_word_%s" % correct_answer_index:
		%_marubatsu.frame = 0
	else:
		%_marubatsu.frame = 1
	
	await _Core_Tweener.new().slide_in(%_marubatsu)
	await get_tree().create_timer(.25).timeout
	await _Core_Tweener.new().slide_out(%_marubatsu)
