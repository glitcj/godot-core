extends Node
class_name _Core_Templates

static var window = preload("res://core/window/_core_window.tscn")

static var portrait = preload("res://nodes/portrait/doomer.portrait.tscn")
static var coin_box_coin = preload("res://nodes/coin_box/doomer.coin_box.coin.tscn")
static var card_mark = preload("res://nodes/card/doomer.card.mark.tscn")

# Recent:
var tscn_gun = "res://nodes/gun/doomer.gun.tscn"
var turn_start_screen_player_input = "res://nodes/turner/turns/doomer.turn.start_screen.player_input.gd"
var turn_world_map_player_input = "res://nodes/turner/turns/doomer.turn.world_map.player_input.gd"

var turn_lambda = "res://nodes/turner/turns/doomer.turn.lambda.gd"
var turn_turns = "res://nodes/turner/turns/doomer.events.gd"

# References:
var turn_field = "res://nodes/turner/turns/doomer.turn.field.gd"
var turn_enemy = "res://nodes/turner/turns/doomer.turn.enemy.gd"
var turn_player = "res://nodes/turner/turns/doomer.turn.player.gd"
var tscn_portrait = "res://nodes/portrait/doomer.portrait.tscn"


# TSCN:
var tscn_doomer = "res://doomer.tscn"
var tscn_Doomer_Getter = "res://doomer.getter.gd"
var tscn_card = "res://nodes/card/node.doomer.card.tscn"
var tscn_card_mark = "res://nodes/card/doomer.card.mark.tscn"
var tscn_message_box = "res://nodes/board/doomer.message_box.tscn"
var tscn_coin_box = "res://nodes/coin_box/doomer.coin_box.tscn"
