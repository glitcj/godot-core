# RPGM Performance Refactor Plan

## Overview

This document describes a set of targeted performance refactors for the RPGM GDScript framework. The system is experiencing frame rate degradation over time, caused by expensive scene-tree searches and full collision-tile rebuilds running inside per-frame callbacks. This plan identifies each problem, explains the root cause, and specifies the exact changes to make.

**Convention:** Every changed location in the code must include a comment starting with `# CLAUDE:` followed by a brief note explaining why the change was made.

---

## Files Involved

- `_RPGM_Script.gd` — base class for event scripts, drives per-frame logic and signal wiring
- `_RPGM_Mover.gd` — handles tile-based movement and collision tile tracking
- `_RPGM_Event.gd` — orchestrator node, manages active script selection

---

## Problem 1 — `_update_tiles_with_rpgm_collision` runs on every `map_position` set

### Root Cause

`_RPGM_Mover.map_position` has a setter. Every time a mover moves one tile, the setter fires `_update_tiles_with_rpgm_collision()`. That function:

1. Calls `get_map().find_children("*", "_RPGM_Mover")` — a full scene-tree walk.
2. For each mover found, calls `(m.get_parent() as _RPGM_Event).get_active_script()`, which itself calls `find_children("*", "_RPGM_Script")` — a **nested** scene-tree walk.
3. Rebuilds the entire `tiles_with_rpgm_collision` static array from scratch.
4. Calls `_update_tilemap_collision_debugger()`, which `queue_free()`s every existing debug `ColorRect` and instantiates new ones.

All of this happens every movement tick per moving entity. With multiple NPCs moving simultaneously, this compounds rapidly.

### Desired Change — Dirty Flag Pattern

Replace the immediate rebuild with a dirty flag. The collision tile list is only rebuilt once per frame at most, and only when something has actually changed.

**In `_RPGM_Mover.gd`:**

- Remove the `_update_tiles_with_rpgm_collision()` call from the `map_position` setter entirely.
- Add a `static var collision_dirty: bool = false`.
- In the `map_position` setter, set `collision_dirty = true` instead of calling the full rebuild.
- Move the rebuild call into `_process()` behind a `if collision_dirty:` guard, then set `collision_dirty = false` after rebuilding.
- The debug rect update (`_update_tilemap_collision_debugger`) should only run when `OS.is_debug_build()` is true (or in editor hint), since it has no gameplay purpose at runtime.

**Approximate structure after change:**

```gdscript
@export var map_position: Vector2i = Vector2i(0, 0):
    set(v):
        map_position = v
        # CLAUDE: removed direct rebuild call here — now uses dirty flag to defer to _process
        collision_dirty = true
        if Engine.is_editor_hint(): _quantise_position()

static var collision_dirty: bool = false

func _process(delta: float) -> void:
    if destination != map_position: state = State.Moving
    else: state = State.Idle
    # CLAUDE: deferred collision rebuild — runs at most once per frame regardless of how many movers moved
    if collision_dirty:
        _update_tiles_with_rpgm_collision()
        collision_dirty = false
```

---

## Problem 2 — Nested `find_children` inside `_update_tiles_with_rpgm_collision`

### Root Cause

Inside the collision rebuild loop, `get_active_script()` is called on each event. `get_active_script()` calls `find_children("*", "_RPGM_Script")` — this is a tree walk per mover, making the overall complexity O(movers × scripts_per_event) on every rebuild.

### Desired Change — Cache Active Scripts on the Event

`_RPGM_Event` already maintains `active_script` as a cached variable. The rebuild loop should read from `event.active_script` directly instead of calling `get_active_script()` again.

**In `_RPGM_Mover.gd`, inside `_update_tiles_with_rpgm_collision()`:**

```gdscript
func _update_tiles_with_rpgm_collision():
    if get_map() == null: return
    tiles_with_rpgm_collision = []
    for m: _RPGM_Mover in get_map().find_children("*", "_RPGM_Mover"):
        if m.get_parent() is _RPGM_Player: continue
        # CLAUDE: use cached active_script from the event instead of calling get_active_script()
        # which internally does another find_children walk — avoids O(n*m) tree searches
        var event := m.get_parent() as _RPGM_Event
        if event == null: continue
        var active := event.active_script
        if active == null or not active.is_collision: continue
        tiles_with_rpgm_collision.append(m.map_position)
    _update_tilemap_collision_debugger()
```

Additionally, the outer `find_children("*", "_RPGM_Mover")` call inside the rebuild still happens every time. To reduce this further, cache the mover list on the map level (see Problem 3).

---

## Problem 3 — `find_children` / `find_parent` called in hot-path helpers

### Root Cause

`_RPGM_Script` defines many helper functions that are called frequently during `_process`:

```gdscript
func get_rpgm(): return find_parent("_RPGM") as _RPGM
func get_player(): return find_parent("_RPGM_Map").find_child("Player") as _RPGM_Player
func get_area(): return get_parent().find_child("Area2D") as Area2D
func get_mover(): return get_parent().find_child("_RPGM_Mover") as _RPGM_Mover
func get_map(): return find_parent("_RPGM_Map") as _RPGM_Map
```

These are not cached — every call traverses the scene tree. Several of them are called inside `_process` on every frame (e.g. `get_rpgm()`, `get_player()`, `get_mover()`).

`_RPGM_Event` has the same pattern with its own set of identical helpers, all uncached.

### Desired Change — Cache All Node References at `_ready`

**In `_RPGM_Script.gd`:**

Extend `_get_components()` (which is already deferred at ready) to cache all frequently-used node references into private vars. Keep the public `get_*` helpers but have them return the cached var instead of doing a tree walk.

```gdscript
# CLAUDE: cached node references — populated once at ready via _get_components
# replaces repeated find_parent/find_child calls in hot paths
var _rpgm_cache: _RPGM
var _map_cache: _RPGM_Map
var _player_cache: _RPGM_Player
var _area_cache: Area2D

func _get_components():
    parent = get_parent()
    _rpgm_cache = find_parent("_RPGM")
    _map_cache = find_parent("_RPGM_Map")
    if _map_cache:
        _player_cache = _map_cache.find_child("Player")
    if parent.find_children("*", "_RPGM_Mover").size() > 0:
        mover = parent.find_child("_RPGM_Mover")
    if parent.find_children("*", "_RPGM_Portrait").size() > 0:
        portrait = parent.find_child("_RPGM_Portrait")
    _area_cache = parent.find_child("Area2D")

func get_core(): return find_parent("_Core") as _Core   # infrequent, leave as-is
func get_rpgm(): return _rpgm_cache
func get_map(): return _map_cache
func get_player(): return _player_cache
func get_area(): return _area_cache
func get_mover(): return mover  # already cached
```

**In `_RPGM_Event.gd`:**

Same pattern. Add cached vars for rpgm, map, player, area, mover and populate at `_ready`.

```gdscript
# CLAUDE: cached references to avoid repeated find_parent/find_child in per-frame calls
var _rpgm_cache: _RPGM
var _map_cache: _RPGM_Map
var _player_cache: _RPGM_Player
var _area_cache: Area2D
var _mover_cache: _RPGM_Mover

func _ready():
    _rpgm_cache = find_parent("_RPGM")
    _map_cache = find_parent("_RPGM_Map")
    if _map_cache:
        _player_cache = _map_cache.find_child("Player")
    _area_cache = find_child("Area2D")
    _mover_cache = find_child("_RPGM_Mover")

func get_rpgm(): return _rpgm_cache
func get_map(): return _map_cache
func get_player(): return _player_cache
func get_area(): return _area_cache
func get_mover(): return _mover_cache
```

---

## Problem 4 — Debug `ColorRect` rebuild runs at runtime

### Root Cause

`_update_tilemap_collision_debugger()` destroys and recreates a `ColorRect` for every collision tile on every collision rebuild. This is intended as a visual debug aid but runs unconditionally at runtime, including in exported builds.

### Desired Change — Gate Behind Debug / Editor Check

Wrap the entire function body in an early return when not in a debug/editor context.

**In `_RPGM_Mover.gd`:**

```gdscript
func _update_tilemap_collision_debugger():
    # CLAUDE: debug visualisation is expensive (queue_free + add_child per tile per rebuild)
    # skip entirely in non-debug runtime builds
    if not OS.is_debug_build() and not Engine.is_editor_hint():
        return
    for r: ColorRect in all_collision_debugging_rects:
        r.queue_free()
    all_collision_debugging_rects = []
    # ... rest of function unchanged
```

---

## Problem 5 — `frame_started` emits every frame on every active script

### Root Cause

In `_RPGM_Script._process`, `frame_started.emit()` is called unconditionally whenever the script is active. This triggers `_wrapped_callable(_on_frame)` for every active script every frame. `_wrapped_callable` itself has guard logic and signal overhead. For scripts that don't override `_on_frame`, this is pure waste.

### Desired Change — Skip Emit if `_on_frame` is Not Overridden

Add a flag set at `_ready` that indicates whether this script instance has overridden `_on_frame`. Only emit `frame_started` if that flag is true.

**In `_RPGM_Script.gd`:**

```gdscript
# CLAUDE: avoids emitting frame_started every frame for scripts that don't use _on_frame
# get_script().has_method won't detect overrides; compare script to base class instead
var _has_on_frame_override: bool = false

func _get_components():
    # ... existing cache setup ...
    # CLAUDE: check if this instance overrides _on_frame — if not, skip frame_started entirely
    _has_on_frame_override = get_script() != _RPGM_Script and get_script().get_method_list().any(
        func(m): return m["name"] == "_on_frame"
    )
```

Then in `_process`:

```gdscript
# CLAUDE: only emit frame_started if the subclass actually overrides _on_frame
if _has_on_frame_override:
    frame_started.emit()
```

> **Note:** GDScript method list inspection can be slightly tricky. An alternative is to have subclasses explicitly set `var uses_frame_callback = true` in their class body. Choose whichever is cleaner for the codebase. The key outcome is the same: don't pay signal dispatch cost for unused callbacks.

---

## Problem 6 — `_update_active_script` triggers a full collision rebuild

### Root Cause

`_update_active_script` in `_RPGM_Event` ends with:

```gdscript
get_mover()._update_tiles_with_rpgm_collision()
```

This is a direct call to the expensive rebuild, bypassing whatever dirty-flag mechanism is put in place by Problem 1's fix. `_update_active_script` is called from `_RPGM_Script._process` whenever `_is_activatable()` changes — potentially multiple times per frame across many scripts.

### Desired Change — Replace Direct Call with Dirty Flag

After Problem 1's fix is in place, replace the direct call with the dirty flag:

**In `_RPGM_Event.gd`, inside `_update_active_script()`:**

```gdscript
func _update_active_script():
    if active_script and active_script._is_activatable():
        return
    if active_script and not active_script._is_activatable():
        active_script._on_deactivated()

    active_script = get_active_script()
    if active_script:
        active_script._on_activated()
    # CLAUDE: replaced direct _update_tiles_with_rpgm_collision() call with dirty flag
    # the rebuild now happens at most once per frame in _RPGM_Mover._process
    _RPGM_Mover.collision_dirty = true
```

---

## Problem 7 — `static var tiles_with_rpgm_collision` on `_RPGM_Mover`

### Root Cause

`tiles_with_rpgm_collision` is declared `static`, meaning it is shared across all instances of `_RPGM_Mover`. This means any mover can trigger a full rebuild that overwrites data for all other movers. It also makes the collision system effectively global state with no clear owner, making it harder to isolate bugs and impossible to support multiple maps simultaneously.

### Desired Change — Move Ownership to the Map

This is a slightly larger structural change. Move `tiles_with_rpgm_collision` and the rebuild logic to `_RPGM_Map`, which is the natural owner (it already owns the `TileMapLayer`s used for tile collision checks).

**In `_RPGM_Map.gd` (new additions):**

```gdscript
# CLAUDE: collision tile list moved here from _RPGM_Mover static var
# _RPGM_Map is the correct owner — it already owns the tile layers and the mover list
var tiles_with_rpgm_collision: Array[Vector2i] = []
var collision_dirty: bool = false

func mark_collision_dirty():
    collision_dirty = true

func _process(_delta):
    if collision_dirty:
        _rebuild_collision_tiles()
        collision_dirty = false

func _rebuild_collision_tiles():
    tiles_with_rpgm_collision = []
    for m: _RPGM_Mover in find_children("*", "_RPGM_Mover"):
        if m.get_parent() is _RPGM_Player: continue
        var event := m.get_parent() as _RPGM_Event
        if event == null: continue
        var active := event.active_script
        if active == null or not active.is_collision: continue
        tiles_with_rpgm_collision.append(m.map_position)
    _update_tilemap_collision_debugger()
```

**In `_RPGM_Mover.gd`:**

- Remove `static var tiles_with_rpgm_collision`
- Remove `static var all_collision_debugging_rects`
- Remove `_update_tiles_with_rpgm_collision()` and `_update_tilemap_collision_debugger()` entirely
- Update `tile_has_rpgm_collision()` to read from the map:

```gdscript
func tile_has_rpgm_collision(position: Vector2i) -> bool:
    # CLAUDE: reads from map-owned collision list instead of static var on _RPGM_Mover
    var map := get_map()
    if map == null: return false
    return map.tiles_with_rpgm_collision.has(position)
```

- In the `map_position` setter, call `get_map().mark_collision_dirty()` if map is available.

> **Note:** Problem 7 is the most structural change. If doing all problems in one pass, do Problem 7 last and make sure Problems 1–6 are consistent with the new ownership model (i.e. `collision_dirty` lives on the map, not on `_RPGM_Mover`).

---

## Change Summary Table

| # | File | Location | Change | Risk | Status |
|---|---|---|---|---|---|
| 1 | `_RPGM_Mover.gd` | `map_position` setter + `_process` | Dirty flag instead of immediate rebuild | Low | **DONE** |
| 2 | `_RPGM_Mover.gd` | `_update_tiles_with_rpgm_collision` | Use `event.active_script` instead of `get_active_script()` | Low | **DONE** |
| 3 | `_RPGM_Script.gd` | `_get_components` + all `get_*` helpers | Cache all node refs at ready | Low | **DONE** |
| 3 | `_RPGM_Event.gd` | `_ready` + all `get_*` helpers | Cache all node refs at ready | Low | **DONE** |
| 4 | `_RPGM_Mover.gd` | `_update_tilemap_collision_debugger` | Gate behind `OS.is_debug_build()` | Low | **DONE** |
| 5 | `_RPGM_Script.gd` | `_process` | Only emit `frame_started` if `_on_frame` overridden | Medium | **DONE** |
| 6 | `_RPGM_Event.gd` | `_update_active_script` | Replace direct rebuild call with dirty flag | Low | **DONE** |
| 7 | `_RPGM_Mover.gd` + `_RPGM_Map.gd` | Collision list ownership | Move static collision state to `_RPGM_Map` | Medium | **DONE** |

---

## Recommended Implementation Order

1. ~~**Problem 2** first — safest, pure read change inside an existing function, no structural impact.~~ **DONE**
2. ~~**Problem 4** — one-line guard, zero risk.~~ **DONE**
3. ~~**Problem 3** — cache node refs in both files; verify `_get_components` deferred call timing is correct (it already uses `call_deferred` in `_RPGM_Script`, match this in `_RPGM_Event`).~~ **DONE** — `_RPGM_Event` uses `_cache_components.call_deferred()` to mirror the `_RPGM_Script` pattern; sibling-node lookup (Player) is safe because the deferred call runs after all `_ready()` calls complete.
4. ~~**Problem 1 + 6 together** — introduce `collision_dirty` flag on `_RPGM_Mover`, update both the setter and `_update_active_script` to use it.~~ **DONE**
5. ~~**Problem 5** — test carefully; make sure override detection works for all existing script subclasses before shipping.~~ **DONE** — uses `get_script_method_list()` (direct-definition only, not inherited) and walks the script chain so multi-level subclasses are detected correctly.
6. ~~**Problem 7 last** — most structural, requires `_RPGM_Map.gd` changes and touching the most files. Do in a separate commit/branch.~~ **DONE** — `tiles_with_rpgm_collision`, `collision_dirty`, `_all_collision_debugging_rects`, `_rebuild_collision_tiles`, and `_update_tilemap_collision_debugger` all live on `_RPGM_Map` now. `_RPGM_Mover` static vars removed.

---

## Notes for Implementation Session

- Do not change any public API signatures (the `get_*` helpers should still exist and return the same types).
- `_get_components` in `_RPGM_Script` is called via `call_deferred` in `_ready` — the caching in `_RPGM_Event._ready` should also be deferred if there's any risk the child nodes aren't in the tree yet at ready time.
- The `static` vars on `_RPGM_Mover` are shared across all instances — be careful when removing them that no other file references `_RPGM_Mover.tiles_with_rpgm_collision` directly (search the project before deleting).
- Every changed line or block must have a `# CLAUDE: ...` comment directly above or inline explaining the reason for the change.
