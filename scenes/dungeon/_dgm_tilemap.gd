@tool
extends Area3D
class_name _DGM_Tilemap


@export_tool_button("Update") var b : Callable = _update_tilemap

func _on_button(): pass

@export var floor_tilemap : TileMapLayer
@export var wall_tilemap : TileMapLayer

const grid_cell_size = 1.

var grid_cell_packed_scene = preload("res://scenes/dungeon/_DGM_Tile.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		%"TileMapLayer Wall".visible = false
		%"TileMapLayer Floor".visible = false
			
			
func _update_tilemap():
	if not floor_tilemap: pass

	for child in get_children():
		if child is not _DGM_Tile: continue  # don't delete the tilemap itself
		child.free()

	for tile2D in floor_tilemap.get_used_cells():
		var tile3D = grid_cell_packed_scene.instantiate() as _DGM_Tile
		tile3D.position.x = tile2D.x * grid_cell_size
		tile3D.position.z = tile2D.y * grid_cell_size  # TileMap Y → 3D Z
		tile3D.type = "floor"
		add_child(tile3D)
		tile3D.owner = get_tree().edited_scene_root
		# tile3D._update_cell()


	for tile2D in wall_tilemap.get_used_cells():
		var tile3D = grid_cell_packed_scene.instantiate() as _DGM_Tile
		tile3D.position.x = tile2D.x * grid_cell_size
		tile3D.position.z = tile2D.y * grid_cell_size  # TileMap Y → 3D Z
		tile3D.type = "wall"
		add_child(tile3D)
		
		tile3D.owner = get_tree().edited_scene_root
		# tile3D._update_cell()


func get_tile_position(position : Vector2i):
	return Vector3(position.x * grid_cell_size, 0, position.y * grid_cell_size)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
