extends Node3D
class_name _DGM_Gun

@onready var ray : RayCast3D = %RayCast3D

var dgm_tile_packed_scene = preload("res://scenes/dungeon/_dgm_tile.tscn")

func get_map(): return find_parent("_DGM_Map") as _DGM_Map


func create_tile(position):
	var tile3D = dgm_tile_packed_scene.instantiate() as _DGM_Tile
	tile3D.position = position
	get_map().add_child(tile3D)
	# get_map().add_child(tile3D)
	tile3D.type = "wall"
	# tile3D.owner = get_tree().edited_scene_root
	tile3D._update_cell()



func fire(): 
	%AnimationPlayer.play("fire")
	await %AnimationPlayer.animation_finished
	%AnimationPlayer.play("idle")
	
	if %RayCast3D.is_colliding():
		create_tile(%RayCast3D.get_collision_point())
	
	
	
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%AnimationPlayer.play("idle")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
