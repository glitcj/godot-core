extends Node2D
class_name _Doomer_Card


signal card_value_changed

enum CardActions {RemoveAllMarks, Randomise, FlipUp, FlipDown}

enum MarkPointers {all_marks, last_added_mark}
enum CardFilters {is_facing_up, is_ready_to_mark_by_player}
enum MarkPositions {Top, Bottom, Left_1, Right_1}

enum CardValue {Ace, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Prince, Queen, King}
enum CardSuite {Diamond, Club, Heart, Spade}

enum CardState {FacingUp, FacingDown}
enum Enumation {AttackUp, AttackDown, Buzz, FlipUp, FlipDown, FlipIn, FlipOut}

static var CardValueToInt := {
	CardValue.Ace: 1,
	CardValue.Two: 2,
	CardValue.Three: 3,
	CardValue.Four: 4,
	CardValue.Five: 5,
	CardValue.Six: 6,
	CardValue.Seven: 7,
	CardValue.Eight: 8,
	CardValue.Nine: 9,
	CardValue.Ten: 10,
	CardValue.Prince: 11,
	CardValue.Queen: 12,
	CardValue.King: 13,
}

static var CardSuiteToSpriteSheetName := {
	CardSuite.Diamond: "cards_diamond",
	CardSuite.Spade: "cards_spade",
	CardSuite.Club: "cards_club",
	CardSuite.Heart: "cards_heart",
} 

var enumation_speeds : Dictionary = {
	Enumation.FlipUp : 2,
	Enumation.FlipDown : 2,
}

@onready var doomer : _Core = find_parent("_Core")
@export var card : AnimatedSprite2D
@export var position_container : CanvasItem
@export var card_viewport : SubViewportContainer
@export var containers_node : CanvasItem


@export var card_scale_multiplier = 1.0

var marks : Array

# card_scale cannot be set with @onready, must be @exported so that 
# animation players can see it
@export var card_scale : Vector2 = Vector2.ONE:
	set(value):
		card_scale = value
		# if is_instance_valid(card):
		if is_instance_valid(card_viewport):
			card_viewport.scale = value * card_scale_multiplier


# Animation players cannot handle reparented nodes.
# Instead, the root node exports proxy animation tracks.
@export var card_position : Vector2 = Vector2.ZERO:
	set(value):
		card_position = value
		if is_instance_valid(card):
			containers_node.position = value

@onready var animation_player := $AnimationPlayer
@onready var sprite := find_children("Card Sprite", "AnimatedSprite2D")[0]

@onready var card_container : CanvasItem = find_children("Card Container", "Container")[0]

# Mark containers
@onready var enemy_bet_continer : CanvasItem = find_children("Enemy Bet Container", "Container")[0]
@onready var player_bet_continer : CanvasItem = find_children("Player Bet Container", "Container")[0]


@onready var player_mark_containers : Array = find_children("Player Mark Container*", "Container")


var value: CardValue = CardValue.Ace:
	set(v):
		value = v
		card_value_changed.emit()
		
var suite: CardSuite = CardSuite.Diamond
var state: CardState = CardState.FacingDown


func flip(direction_ : Variant, wait_for_flip : bool = false):
	assert(direction_ is _Doomer_Card.CardState or  direction_ == null)
	
	if direction_ == null:
		if direction_ == _Doomer_Card.CardState.FacingUp:
			direction_ = _Doomer_Card.CardState.FacingDown
		else:
			direction_ = _Doomer_Card.CardState.FacingUp
		
	if direction_ == state and wait_for_flip:
		await play_enumation(Enumation.Buzz)
	elif direction_ == state and not wait_for_flip:	
		play_enumation(Enumation.Buzz)
	elif direction_ == _Doomer_Card.CardState.FacingUp and wait_for_flip:
		await play_enumation(Enumation.FlipUp)
	elif direction_ == _Doomer_Card.CardState.FacingUp and not wait_for_flip:
		play_enumation(Enumation.FlipUp)
	elif direction_ == _Doomer_Card.CardState.FacingDown and wait_for_flip:
		await play_enumation(Enumation.FlipDown) # flip_down()
	elif direction_ == _Doomer_Card.CardState.FacingDown and not wait_for_flip:
		play_enumation(Enumation.FlipDown)

func play_enumation(enumation : _Doomer_Card.Enumation, wait : bool = true):
	var _speed = 1
	if enumation in enumation_speeds.keys():
		_speed = enumation_speeds[enumation]
	
	animation_player.play(Enumation.keys()[enumation], -1, _speed)
	if wait:
		await animation_player.animation_finished

func queue_enumation(enumation : _Doomer_Card.Enumation, wait : bool = true):
	animation_player.queue(Enumation.keys()[enumation])
	if wait:
		await animation_player.animation_finished
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_state_machine()
	
func _update_state_machine():
	if state == CardState.FacingUp:
		_while_card_is_facing_up()
	if state == CardState.FacingDown:
		_while_card_is_facing_down()


func _while_card_is_facing_down():
	if not sprite.animation == "cards_other" or not sprite.frame == 0:
		show_card_face_down_sprite()

func _while_card_is_facing_up():
	if not sprite.animation == CardSuiteToSpriteSheetName[suite] or not sprite.frame == CardValueToInt[value] - 1:
		show_card_face_up_sprite()

func set_random_card_value_and_suite():
	value = CardValue.values()[randi()%CardValue.size()]
	suite = CardSuite.values()[randi()%CardSuite.size()]
	
# Used by animation player	
func _change_card_state(state_: CardState):
	state = state_

func show_card_face_up_sprite():
	sprite.animation = CardSuiteToSpriteSheetName[suite]
	sprite.frame = CardValueToInt[value] - 1

func show_card_face_down_sprite():
	sprite.animation = "cards_other"
	sprite.frame = 0

func next_available_mark_container(opponent : _Core.Opponents):
	if opponent == _Core.Opponents.Enemy:
		return enemy_bet_continer
	elif opponent == _Core.Opponents.Player:
		return player_bet_continer
		

func add_mark(mark_type : _Doomer_Card_Mark.MarkType, opponent: _Core.Opponents , wait_for_mark : bool = false):
	var mark : _Doomer_Card_Mark = _Core_Templates.card_mark.instantiate()
	mark.mark_type = mark_type
	# mark._update_mark_type()
	
	var container = next_available_mark_container(opponent)
	container.add_child(mark)
	if wait_for_mark:
		await mark.ready
		
	marks.append(mark)
	
func remove_marks(pointer : _Doomer_Card.MarkPointers, wait_for_each_mark : bool = false):
	if pointer == _Doomer_Card.MarkPointers.all_marks:
		while marks.size() > 0:
			var mark = marks.pop_back()
			if wait_for_each_mark:
				await mark.remove()
			else:
				mark.remove()

func is_ready_to_bet_by_enemy():
	return state == CardState.FacingUp and enemy_bet_continer.get_children().size() < 1

func is_ready_to_bet_by_player():
	return state == CardState.FacingUp and player_bet_continer.get_children().size() < 1

func is_complying_with_any_filter(filters : Array):
	return
