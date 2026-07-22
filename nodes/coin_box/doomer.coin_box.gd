extends Node2D
class_name _Doomer_Coin_Box

@onready var doomer : _Core = find_parent("_Core")
@export var container : CanvasItem
@export var viewport : SubViewport
@export var holder : _Core.Opponents:
	set(v):
		holder = v
		if is_node_ready():
			_on_holder_assignment()
		
@onready var coins : Node2D = find_child("Coins")
@onready var spawner : Area2D =  find_child("Spawner")

@onready var gravity_area : Area2D = find_children("Area2D Gravity")[0]
@onready var gravity_vector : Vector2:
	set(v):
		gravity_vector = v
		gravity_area.gravity_direction = gravity_vector
		
var spawn_point_randomness = Vector2(1300, 100)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_on_holder_assignment()
	add_coins.bind(20).call_deferred()
	
func _on_holder_assignment():
	rotation = PI if holder == _Core.Opponents.Enemy else 0.0
	gravity_vector = Vector2(0, -1) if  holder == _Core.Opponents.Enemy else Vector2(0, 1)

func add_coins(count : int = 1):
	var coin : RigidBody2D
	
	var coin_batch = 2
	for batch_i in range(int(count/coin_batch)):
		for i in range(coin_batch):
			coin = _Core_Templates.coin_box_coin.instantiate()
			coin.visible = false
			coins.add_child(coin)
			coin.visible = true

			
			coin.position = spawner.position 

			coin.position.x += (randi() % int(spawn_point_randomness.x) - (float(spawn_point_randomness.x)/2))
			
			coin.position.y += (randi() % int(spawn_point_randomness.y) - (float(spawn_point_randomness.y)/2))
			
		await doomer.get_lambdas().waiter(0.01)
		
