## Godot 3D gotchas, grounded in DGM — press F1 and search "_Gotchas_3D".
##
## Documentation-only class: no code, never instantiate. Mirror of
## [code]other/docs/md/how-to-avoid-godot-3d-gotchas.md[/code] (the canonical
## copy — update both when adding entries).
##
## [br][br][b]Yaw on the body, pitch on the camera — never pitch the body.[/b]
## Applying mouse-look pitch to the CharacterBody3D itself (as
## _dgm_player.gd:47 does, unclamped) tilts the collision capsule and fights
## move_and_slide()'s up_direction. Split it, and clamp pitch:
## [codeblock]
## rotation.y += -input.x * sensitivity                 # yaw -> body
## %Camera3D.rotation.x = clamp(
##     %Camera3D.rotation.x + input.y * sensitivity, -1.2, 1.2)  # pitch -> camera
## [/codeblock]
##
## [br][br][b]Don't scale physics — size it.[/b] Scale multiplies down the
## whole subtree and into things you don't expect: a scaled RayCast3D's ray
## length is target_position × every ancestor scale (DGM's gun ray is
## 10 × 5 × 1.2 × 1.2 with no comment saying so), and scaled CollisionShape3Ds
## are slow and glitchy in Godot physics. Keep every physics-related node at
## scale (1,1,1); set shape.size, target_position, and mesh dimensions
## instead. Gizmo-dragged transforms full of e-07 float dust are the smell.
##
## [br][br][b]Imported models disagree about "forward".[/b] look_at() points
## -Z at the target, but every glb/fbx export has its own idea of forward —
## DGM's godette needs + PI where the dummy doesn't (the "Why pi ?" comment
## in _wrapped_inherited_godette.gd:25). Fix the orientation once at import
## (rotate the model's root in the inherited scene), not with per-model magic
## constants in movement code. Also: look_at() errors when the target equals
## the node's origin — guard it.
##
## [br][br][b]global_position only exists inside the tree.[/b] Setting a
## spawned node's position from a global point BEFORE add_child writes a
## global coordinate into a local transform — it works only while every
## ancestor sits at identity, and silently skips ancestor scale (DGM's
## gun-spawned walls are 1/10th the size of grid walls). Order matters:
## [codeblock]
## add_child(tile)
## tile.global_position = raycast.get_collision_point()
## [/codeblock]
##
## [br][br][b]transparent_bg erases the sky.[/b] A 3D SubViewport's sky
## renders into the alpha channel — with transparent_bg = true the sky is
## transparent when composited and simply vanishes. 2D viewports here use
## transparent_bg; the DGM 3D viewports deliberately must not (the note in
## _dgm.gd:15).
##
## [br][br][b]SubViewports share one World3D unless told otherwise.[/b]
## Without own_world_3d = true, every SubViewport inherits the root window's
## World3D — DGM's DirectionalLight3D and WorldEnvironment are therefore
## GLOBAL, and a second 3D scene would collide with them (one WorldEnvironment
## per world). Suspending a viewport stops rendering and processing but does
## NOT remove its static bodies or lights from the shared world — DGM's 1263
## wall bodies stay in the physics space while another scene runs.
##
## [br][br][b]Never toggle collision inside a physics callback.[/b] Disabling
## a CollisionObject (or freeing it) from inside area_entered / body_entered
## is flushing-queries territory and errors. Defer it — already the fix in
## _core_viewport.gd:64, reached via DGM's teleporter:
## [codeblock]
## %CollisionShape3D.set_deferred("disabled", true)
## [/codeblock]
##
## [br][br][b]An empty _process still costs — times every instance.[/b] A
## script with "func _process(delta): pass" gets dispatched every frame on
## every instance: DGM spawns 1263 tiles, so that's 1263 pointless calls per
## frame (_dgm_tile.gd:29). Delete unused _process/_physics_process
## overrides, or call set_process(false) in _ready.
##
## [br][br][b]Name your 3D collision layers before you need them.[/b] 3D
## layers are separate from 2D layers (layer_names/3d_physics/... in project
## settings) and everything defaults to layer 1 / mask 1 — in DGM the player,
## 1263 walls, both NPCs, and two Area3Ds all collide indiscriminately. Name
## layers (player / world / triggers / npc) the moment a second kind of body
## exists; retrofitting masks later means touching every scene.
##
## [br][br][b]Web has no Forward+ — 3D exports run Compatibility.[/b] The web
## export always uses the Compatibility renderer: no SDFGI or volumetric fog,
## screen-space effects missing, glow and Filmic tonemapping (both enabled in
## DGM's WorldEnvironment) look and cost different. Test 3D scenes in a web
## build early, not after tuning visuals in Forward+. Related export traps:
## scenes only reached via preload() in scripts (like _dgm_tile.tscn) must be
## ticked in the export tree or they're missing at runtime, and 4k HDR
## panoramas (rogland_clear_night_4k.exr) are megabytes of pck for a sky —
## downscale for web.
class_name _Gotchas_3D
extends Object
# CLAUDE: documentation-only class — renders the 3D gotchas doc in the
# editor's built-in Help (F1 -> "_Gotchas_3D"). Canonical source is the .md
# in other/docs/md/; keep the two in sync. Explicit [br][br] because blank
# ## lines don't render as paragraph breaks in the help.
