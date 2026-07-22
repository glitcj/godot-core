extends Node2D
class_name _Doomer_Portrait

signal animation_loop_finished

@onready var doomer : _Core = find_parent("_Core")

enum Portraits {Face, Coin, TurnBoard, Gun, StakeBoard}
enum Animations {
	RESET, Idle, Damage, Attack, Defend, AttackRallyEnd,
	UpdateTurn, BoardIn, BoardOut, show_in_background, hide_in_background
	}	

var turnboard_turn_name : String = "Null"
var stakeboard_stake : int = 100

@onready var turnboard_label : Label = $"TurnBoard/Turn Board Control/Label Node/VBoxContainer/CenterContainer/Label"
@onready var stakeboard_label : Label = $"StakeBoard/Turn Board Control/Label Node/VBoxContainer/CenterContainer/Label"

@export var portrait : Portraits:
	set(value):
		portrait = value
		
var animation_player : AnimationPlayer
var sprite : Node

@export var container : CanvasItem

var AnimationMap : Dictionary = {
	Animations.RESET : &"RESET",
	Animations.Idle : &"Idle",
}

@onready var PortraitMap : Dictionary 
@onready var all_portrait_sprites : Array = get_children() # [$Head, $Coin, $"TurnBoard", $Gun, $StakeBoard]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for _portrait in Portraits.values():
		PortraitMap[_portrait] = [
			get_node("%s/AnimationPlayer" % [Portraits.keys()[_portrait]]), 
			get_node("%s" % [Portraits.keys()[_portrait]])
			]
	
	_update_portrait()
	queue_enumation(Animations.RESET)
	queue_enumation(Animations.Idle)
	
	

		
		
	
	if container:
		doomer.ready.connect(_reparent_to_container)
	# portrait_changed.connect(_on_portrait_changed)

func _reparent_to_container():
	reparent(container)
	position = Vector2.ZERO

func _update_portrait():
	animation_player = PortraitMap[portrait][0]
	sprite = PortraitMap[portrait][1]

	for s in all_portrait_sprites:
		s.visible = false
	sprite.visible = true
	
func play_enumation(enumation : Animations, wait : bool = false):
	animation_player.stop()
	animation_player.play(Animations.keys()[enumation])
	if wait:
		await animation_player.animation_finished


func play_enumation_queue(enumations : Array, wait : bool = false) -> void:
	animation_player.stop()
	
	if not wait:
		for enumation : _Doomer_Portrait.Animations in enumations:
			animation_player.play(Animations.keys()[enumation])
			await _wait_for_animation_end()

			
	else:
		for enumation : _Doomer_Portrait.Animations in enumations:
			animation_player.play(Animations.keys()[enumation])
			var animation_name = Animations.keys()[enumation]			
			if animation_name == "Damage":
				pass
			await _wait_for_animation_end()

func _wait_for_animation_end():
	var animation = animation_player.get_animation(animation_player.current_animation)
	
	if animation.loop_mode == Animation.LOOP_NONE:
		await animation_player.animation_finished
	else:
		await animation_loop_finished
		

func queue_enumation(enumation : Animations, wait : bool = false):
	animation_player.queue(Animations.keys()[enumation])
	if wait:
		await animation_player.animation_finished
	
func _update_turnboard_label():
	turnboard_label.text = turnboard_turn_name
	
func _emit_animation_loop_finished():
	animation_loop_finished.emit()
