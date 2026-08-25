# RPGM engine hardening checklist

Goal: make the rpgm engine sturdy *before* devving the first real game in it.
Finish line (see "When to stop" at the bottom): rebuild the existing level-1
content on the hardened engine as the acceptance test — then stop hardening
and start the game.

Decision on record: the game keeps **one map scene** (`_rpgm_map.tscn`) with
embedded scripts, version-controlled in git. The owner prefers fewer files and
a smoother dev cycle over splitting maps into separate scenes/files. The
checklist below works within that decision.

---

## 1. Authoring hygiene (within the single-map setup)

Even with one map scene and embedded scripts, these cost little and pay daily:

- [ ] **Replace name-string wiring with `@export` NodePaths/references.**
      There are ~53 `find_child`/`find_parent` calls on magic names
      (`"Player"`, `"L1 Base"`, `find_event("_npc_1_1")`,
      `find_child("_player_position_5_1")`, ...). Renaming a node in the
      editor silently breaks the game at runtime. Exported references break
      *visibly* in the inspector instead.
- [ ] **Promote copy-pasted embedded logic into common script classes.**
      The `_on_viewport_finished → change_viewport → show_messages` mini-game
      handoff block exists 4× across embedded scripts; the
      "`l2_enemies_count += 1; queue_free()`" body exists 3×. Embedded scripts
      that just subclass a `_RPGM_Common_Script_*` and set `@export`s are
      fine; embedded scripts that duplicate whole behaviours are bug farms.
- [ ] **Decide the fate of `_RPGM_Event_Data`.** The Resource + its `.tres`
      exist but are referenced by nothing. Either grow it into the event data
      layer or delete it.
- [ ] **Stop shipping every game in the pck.** `_core.tscn` instances all six
      games side-by-side in `Scenes/Scene Grid`, so an exported rpgm game
      carries DGM/Birds/Swiper/Scroller assets and scenes. Independent of the
      one-map decision.
- [ ] Move the reference/teaching shaders (`*_reference*.gdshader`, ~half of
      the 19 shaders in `viewports/rpgm/shaders/`) out of the engine folder.

## 2. Save/load — build it before real content exists

There is currently **zero persistence** (no `user://`, `ConfigFile`,
`ResourceSaver`, or JSON in game code). Retrofitting saves into a finished RPG
is the classic nightmare; every system built without serialization in mind
resists it.

- [ ] Define the canonical game state: a variables dictionary, per-event
      `state`, player position (+ current map region).
- [ ] Replace `_RPGM_Variables`'s four hardcoded static ints
      (`l1..l4_enemies_count`) with that dictionary — quest checks like
      `if get_variables().l2_enemies_count == 2` should read named keys.
- [ ] Make all systems read/write through the canonical state.
- [ ] Implement save/load (e.g. `ConfigFile` or JSON in `user://`) while the
      state is still small.
- [ ] Save/load round-trip becomes a unit test (see §5).

## 3. Centralize input

- [ ] One input layer: the player controller emits intents/actions; scripts
      subscribe. Today every `_RPGM_Script` independently polls `ui_accept`
      in `_process` (`_rpgm_script.gd:119`) and the player polls
      `ui_up/down/left/right` directly — cost scales with event count, and
      gamepad/touch/rebinding are impossible to add cleanly.
- [ ] Route through the project input map with rpgm-named actions (the
      defined `ui_w/a/s/d` actions are currently unused by rpgm).

## 4. Known landmines — fix list

Specific bugs to kill before they're buried under content:

- [ ] `_rpgm_mover.gd:73` — `while tile_has_collision(...): await
      process_frame` waits forever if the tile never clears; a patrolling
      ghost can soft-lock the game via the latched `interrupt_player`.
- [ ] `_rpgm_player.gd:107` — `next_direction / next_direction.abs()`
      divides 0/0 on axis-aligned input; works only by NaN→int accident.
- [ ] `_rpgm_player.gd:86` — `print()` every frame during movement (hurts
      web builds badly). Also `_core_window.gd:65` prints per dialogue line,
      plus 3 prints inside embedded map scripts.
- [ ] `_rpgm_script.gd` reentrancy guard (`trigger_is_running`, string-keyed
      bool dict) — an `await` that never resumes leaves the flag stuck true
      forever (the mover bug above is exactly such an await).
- [ ] `_rpgm_script.gd:122` — adjacency test uses Euclidean
      `.abs().length() <= 1`; diagonals pass at ≈1.414 by coincidence. Use
      Manhattan/Chebyshev.
- [ ] `_get_direction_to_player()` asserts axis-alignment — crashes in debug,
      silently misbehaves in release, on any diagonal offset.
- [ ] `_rpgm_mover.gd:149` — `tiles_with_rpgm_collision` is a linear-scanned
      Array; make it a Dictionary set.
- [ ] `_rpgm_mover.gd:125` — `tile_has_collision` string-looks-up
      `"rpgm-collision"` across all 9 layers per call, inside `move()`'s
      while loop; cache the layer lookup.
- [ ] `_rpgm_player.gd:63` — per-frame `scripts_currently_on_map()` does a
      full recursive `find_children` tree walk (new Array, 60×/sec); cache
      and invalidate instead.
- [ ] `_rpgm_portrait.gd:66-91` — 12 hardcoded shader `load()` calls in an
      if-ladder keyed on an enum string; use a dict or per-type `.tres`
      material. Also the documented `%AnimationTree` not-found errors
      (~18/boot per `ERRORS.md`).

## 5. Core ↔ rpgm decoupling

Core should compile and run without rpgm:

- [ ] `core/autoload/_get.gd` (`grab` autoload) returns `_RPGM_Map` /
      `_RPGM_Event` — core depends on a game folder.
- [ ] `core/_core_tweener.gd:57-67` — generic tween utility casts to
      `_RPGM_Mover`.
- [ ] `_Core_Log` lives in `viewports/birds/` but is used by core and rpgm —
      move it into `core/`.
- [ ] `_RPGM.finished` is declared, asserted on by `_Core_Viewport._ready`,
      and **never emitted** — the intended lifecycle handback is dead; embedded
      scripts call `get_core().change_viewport(...)` directly. Pick one
      mechanism and delete the other.
- [ ] `_core.gd` mixes stack and queue: `change_viewport`/`add_viewport`
      `append()` but `remove_viewport` does `pop_at(0)` — nesting more than
      one viewport returns to the wrong scene.
- [ ] `_Core_Templates` carries ~10 dead `res://nodes/...` preload paths from
      a previous project; `_Core_Variables._load_koran()` parses the Quran
      CSV at boot for every game.
- [ ] Turner: `_Core_Turner.insert_turn`/`start_next_turn` have no callers
      and two conflicting ownership models (`remove_child` without free vs
      `queue_free`). Fix or delete.

## 6. Tests — only where they pay

- [ ] **Fix the headless check first.** The boot check's exit code is
      meaningless (`recursive_mutex` shutdown abort) and the log is drowned
      by ~26k DGM TileSet errors. Until a headless run can say pass/fail,
      automated testing is built on sand. (Per `CLAUDE.md`: never run
      headless while the editor is open.)
- [ ] **gdUnit4 (or GUT) for pure logic only** (~a dozen tests): mover grid
      math, collision lookup, direction/adjacency, page-selection
      (`_is_active`) logic, save/load round-trip.
- [ ] **A smoke-test map, not scene unit tests**: one small map region
      exercising every engine feature — talker, patrol, teleport, area
      trigger, state change, mini-game handoff, save/load. Playable start to
      finish in ~60 seconds after any engine change. Higher ROI than mocking
      scene trees.

## 7. What NOT to do

Don't gold-plate systems the first game won't use: localization frameworks,
generic/visual event editors, mod support, a full RPG-Maker-style page UI.
Engines only get sturdy by shipping games in them.

## When to stop

Use this yardstick: **rebuild the existing level-1 content on the hardened
engine.** Whatever that rebuild forces you to build (save/load, common script
prefabs, input layer) is genuinely needed — build it. Whatever it does *not*
force (localization, editors, mod support) you don't need yet — defer it
until a real game demands it. When level 1 plays through cleanly on the new
foundations, stop hardening and start game one.
