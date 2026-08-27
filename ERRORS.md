# Known runtime errors (headless boot, 2026-08-07)

High-level list of errors currently emitted by a headless boot check
(`--headless --quit-after 60`). To be fixed one by one; none of them are
new — all reproduce on a clean boot after the getter refactor.

## 1. Converted-TileSet spam under headless (~26k errors)

- `Cannot create tile. The tile is outside the texture or tiles are already
  present in the space the tile would cover.` (~8.8k per boot)
- `TileSetAtlasSource has no tile at (x, y).` — many coordinates, mostly
  columns 8–9, rows 16–35.
- Source: **not** the DGM runtime tile builder (it only calls
  `get_used_cells()` and never touches a TileSetAtlasSource). The errors
  come from *loading* the RPG-Maker-converted TileSet resources
  (`assets/rpgmaker/converted/tilesets/*.tres`) under `--headless`: the
  atlas texture reports size 0 there, so every `create_tile` fails, and each
  subsequent terrain/peering-bit property on the missing tile emits
  "has no tile at (x, y)". The tile data itself is valid — all declared
  atlas coords fit their PNGs — and normal (non-headless) runs are fine.
  Headless-only artifact; harmless but drowns the log.

## 2. RPGM portrait animation errors

- `Node not found: "%AnimationTree"` (~18 per boot) — the `facing` setter in
  `viewports/rpgm/components/_rpgm_portrait.gd:24` assumes every portrait
  scene has an AnimationTree; some don't.
- `Condition "p_animation_library.is_null()" is true` — same setter, playing
  the "actioned" animation when the animation library isn't loaded.

## 3. Shutdown abort (headless only)

- `libc++abi: terminating due to uncaught exception ... recursive_mutex lock
  failed: Invalid argument` on quit. Known headless shutdown issue; makes
  the exit code useless for CI-style checks.
