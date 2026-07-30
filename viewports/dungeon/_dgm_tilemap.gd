@tool
extends Area3D
class_name _DGM_Tilemap
## Generates the 3D _DGM_Tile grid from the 2D TileMapLayer data.
##
## The 2D layers are the single source of truth; the 3D tiles are derived and
## never saved into the map scene. At runtime _ready() builds them on load.
## In the editor the Update button builds a session-only preview: the spawned
## tiles are deliberately left with owner == null, so they render in the
## viewport but stay out of the Scene dock and are skipped by the scene saver
## (which only writes nodes owned by the edited scene root). The preview goes
## stale when the 2D layers are edited — press Update again to refresh.
##
## Implications of owner == null (all editor/serialization-side, none gameplay):
## - Skipped by the scene saver and PackedScene.pack(); exists only while its
##   tree is alive, freed with the scene on close/reload.
## - Hidden from the Scene dock: can't be selected there, edited persistently,
##   or referenced from saved nodes (any NodePath to it would dangle on reload).
## - unique_name_in_owner has nowhere to register, so %-lookups targeting the
##   node itself fail (its internal nodes are unaffected — see _update_tilemap).
## - Untracked by undo/redo and unsaved-changes detection.
## Parenting, rendering, physics, signals, groups, $-paths and freeing all
## behave normally — the engine only consults owner when serializing a tree.
##
## Parent vs owner:
## - parent: position in the live tree. Set implicitly by add_child(). Every
##   node in the tree has one. Drives transforms, rendering, physics, $-paths,
##   propagation (_ready/_process, visibility, pause) and lifetime (freed with
##   its parent). Runtime concept — what the node IS right now.
## - owner: membership in a scene document. Never set implicitly by add_child();
##   assigned explicitly, or by instantiate() (internals -> their scene root),
##   or by the editor when you add nodes in the dock. May be null. Drives scene
##   saving, the Scene dock listing and %-name registration. Serialization
##   concept — which .tscn the node BELONGS to when saved.
## - Constraint: an owner must be an ancestor, so owner implies parent-chain,
##   never the reverse. Reparenting keeps owner only while it remains an
##   ancestor (cleared otherwise); a null owner never blocks runtime behavior.


## Rebuilds the 3D tiles from the current 2D layer data (editor preview).
@export_tool_button("Update") var b : Callable = _update_tilemap

func _on_button(): pass

@export var floor_tilemap : TileMapLayer
@export var wall_tilemap : TileMapLayer

const grid_cell_size = 1.

var grid_cell_packed_scene = preload("res://viewports/dungeon/_dgm_tile.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		%"TileMapLayer Wall".visible = false
		%"TileMapLayer Floor".visible = false
		_update_tilemap()
			
			
## Frees all existing _DGM_Tile children and re-instantiates one tile per used
## cell of the floor/wall layers. Spawned tiles keep owner == null on purpose:
## setting owner = edited_scene_root would bake them into the map .tscn on save
## (hundreds of derived nodes, stale on tilemap edits). Their internal nodes are
## still owned by each tile root via instantiate(), so %-lookups inside
## _dgm_tile.gd keep working.
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

	for tile2D in wall_tilemap.get_used_cells():
		var tile3D = grid_cell_packed_scene.instantiate() as _DGM_Tile
		tile3D.position.x = tile2D.x * grid_cell_size
		tile3D.position.z = tile2D.y * grid_cell_size  # TileMap Y → 3D Z
		tile3D.type = "wall"
		add_child(tile3D)


func get_tile_position(position : Vector2i):
	return Vector3(position.x * grid_cell_size, 0, position.y * grid_cell_size)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
