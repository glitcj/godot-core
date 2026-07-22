extends Node2D
class_name _Doomer_Gun

@onready var hand_cards = find_children("Card", "_Doomer_Card")
@onready var card_labels = find_children("Label Card *", "Label")

@onready var coin_box = $"MarginContainer Coin Box/CenterContainer 2/CoinBox"

@export var holder : _Core.Opponents:
	set(v):
		holder = v
		_update_layout()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for card : _Doomer_Card in hand_cards:
		card.card_value_changed.connect(_on_cards_value_changed)
	_update_layout()
	
func _update_layout():
	var hboxes = find_children("*", "HBoxContainer", true, false)
	for hbox : HBoxContainer in hboxes:
		hbox.layout_direction = Control.LAYOUT_DIRECTION_LTR if holder == _Core.Opponents.Player else Control.LAYOUT_DIRECTION_RTL


func _on_cards_value_changed():
	for i in range(card_labels.size()):
		var card : _Doomer_Card = hand_cards[i]
		var label : Label = card_labels[i]
		label.text = str(card.value)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
