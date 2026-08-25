# Save/load plan (engine-checklist §2)

## Approach: battery save, not savestate

Two ways to "save a game", using the GBA as the reference:

- **Savestate** (what the *emulator* does): snapshot the entire machine —
  RAM, registers, everything. Possible only because the emulated machine is
  a closed, finite box.
- **Battery save** (what the *game cartridge* does): write a few KB of
  explicit facts — flags, inventory, position — and on load, the game
  **reconstructs** the world from those facts.

In Godot the running game is not a closed box: it's a live scene tree full of
tweens, `await`-suspended coroutines, signal connections, and node references.
There is no reliable way to snapshot that (`PackedScene.pack()` doesn't
capture script state, running tweens, or suspended coroutines). So rpgm does
**battery-save style**: define a small canonical state, save that, and on load
boot the scene fresh and *apply* the state to it.

The structural rule that falls out of this:

> **Anything that must survive a save must exist as data, and the world must
> be reconstructible from that data alone.** A change made only to the live
> tree (e.g. `queue_free()` a defeated enemy) is invisible to the save system
> and comes back on load.

## Canonical state shape

One dictionary, one owner (a `_RPGM_State` or similar on the rpgm viewport):

```gdscript
{
	"version": 1,
	"variables": { "l2_enemies_count": 2, ... },   # replaces _RPGM_Variables statics
	"events":    { "_npc_1_1": "B", "_enemy_2_3": "G", ... },  # event name -> state
	"player":    { "map_position": [12, 7], "facing": [0, 1] },
}
```

- **Keys are event node names.** Fine in the single-map-scene setup, but note:
  node names become part of the save format — renaming an event breaks old
  saves (acceptable pre-release; add migration only if ever needed).
- **`version` field from day one.** Costs nothing now, enables migration later.

## Required structural changes

1. **`_RPGM_Variables`: 4 static ints → the `variables` dictionary.**
   Quest checks like `l2_enemies_count == 2` become named-key reads. This is
   the single source of truth for global game state.

2. **Event state must round-trip.** `_RPGM_Event.state` (enum A–G) is already
   data — good. Missing half: an *apply* path. On load, set each event's
   `state` from the save and let the existing `_is_active` machinery on its
   scripts react. Events whose scripts don't fully derive behaviour from
   `state` need fixing so they do.

3. **Stop destroying, start marking.** Defeated enemies currently
   `queue_free()` — unrecoverable from data. Replace with a state transition
   (e.g. reserve one enum value as "removed"); the event hides/disables
   itself when in that state, both at runtime and when the state is applied
   on load. Same for any one-shot chest/door/trigger.

4. **Player position/facing** read from and written to the state dict
   (teleport + face on apply).

5. **Save only at safe moments.** Saving is allowed only when the player is
   idle and no `_RPGM_Script` trigger is running (`is_running()` all false).
   This sidesteps serializing mid-dialogue, mid-tween, mid-coroutine states
   entirely — the hardest problem deleted by a design rule.

6. **Persistence layer** — small and boring:
   - `collect_state() -> Dictionary` — scrape variables + event states +
     player into the dict.
   - `apply_state(state: Dictionary)` — push the dict back into the world.
   - `save_to_disk(slot)` / `load_from_disk(slot)` — JSON at
     `user://save_<slot>.json` (JSON keeps saves readable/debuggable; swap
     for ConfigFile if preferred).
   - Load flow: boot/reset the map scene fresh, then `apply_state`.

## Phases

- [ ] **P1 — state object**: create the state owner, migrate
      `_RPGM_Variables` statics into `variables`, route all reads/writes
      through it. No disk I/O yet; game behaves identically.
- [ ] **P2 — collect/apply**: implement `collect_state`/`apply_state` for
      variables + player. Debug key: collect, print, apply — verify no-op.
- [ ] **P3 — events**: event states in collect/apply; convert `queue_free()`
      deaths and one-shots to state transitions.
- [ ] **P4 — disk**: JSON save/load to `user://`, version field, safe-moment
      guard, hook up to input/menu.
- [ ] **P5 — verify**: unit test the round-trip
      (`apply_state(collect_state())` is a no-op; save→load→collect equals
      original). Smoke test: defeat an enemy, save, quit, load — enemy stays
      dead; load an older save — enemy is back.

## Out of scope (defer until a game demands it)

Multiple save slots UI, autosave, save thumbnails/metadata, cross-version
migration, encrypting saves, saving mid-cutscene.
