# CLAUDE.md

## What this repo is

A reusable game "core" (Godot 4.7) for building many simple games on top of
shared infrastructure. The individual games/scenes under `viewports/` are as
much test-beds for the core as they are games. The owner codes and maintains
this hands-on.

## Claude's role

- **Review and refactor.** Improve specific parts only when explicitly asked.
- **Never make many changes at once.** Small, focused diffs — one concern per
  change. When a fix suggests further improvements, mention them, don't do them.
- When asked a question ("why is X happening?"), investigate and answer —
  don't apply fixes until asked.
- **Mark every change with a `# CLAUDE:` comment** explaining what was done
  and why, e.g.:
  ```gdscript
  # CLAUDE: cache extracted frames — rebuilding an ImageTexture every
  # animation tick caused constant stutter on web builds
  ```

## Conventions

- Tabs for indentation, always.
- `res://` paths are case-sensitive in web exports; macOS hides mismatches.
  Match file casing exactly.
- Docs live in `other/docs/` as `how-to-*.md` files. Repo-level build doc:
  `how-to-build-and-host-project-in-html.md`.

## Architecture

- `_core.tscn` / `_core.gd` (`_Core`) — orchestrator and main scene. All game
  scenes are instantiated side-by-side in the `Scenes/Scene Grid`; the active
  one is displayed via the `Current Viewport` TextureRect showing its
  SubViewport texture.
- `core/_core_viewport.gd` (`_Core_Viewport`) — base class for every game
  scene; each is a `SubViewportContainer` with a child named exactly
  `SubViewport`. Lifecycle: Start > Activate > Deactivate > Finish, via
  `_on_viewport_start` / `_on_viewport_finish`. Subclasses override these and
  must call `super()`.
- **Suspend/resume policy lives in `_Core`, not in the viewport class**:
  `_suspend()` (viewport `UPDATE_DISABLED` + `PROCESS_MODE_DISABLED`) and
  `_resume()` are called by the transition functions. `change_viewport`
  suspends the outgoing scene; `add_viewport`/`remove_viewport` keep the
  stacked background scene running. Scenes boot suspended (`_ready`).
  Caveats: audio ignores suspension (stop it in `_on_viewport_finish`);
  signals and coroutines still fire on suspended nodes.
- `core/turner/` — turn system (`_Core_Turn` subclasses per scene).
- `viewports/<name>/` — one folder per game scene (rpgm, dgm, swiper,
  starter, birds, quizer, ...). RPGM-specific pattern: `_RPGM_Script` event
  scripts with cached node refs, `_RPGM_Portrait` with a static frame cache
  feeding shaders standalone 0→1-UV textures.
- `assets/` — art packs (~623MB). Nearly every pack is referenced somewhere;
  don't assume a folder is unused without checking references.

## Web export

- Preset "Web" in `export_presets.cfg` exports to `build/web/` (gitignored).
- Rebuild: `/Applications/Godot.app/Contents/MacOS/Godot --headless
  --export-release "Web" build/web/index.html`, then hard-refresh
  (Cmd+Shift+R) — the pck/wasm cache aggressively.
- Test locally: `python3 -m http.server` in `build/web` (file:// won't work).
- Web runs the Compatibility renderer (not Forward+), wasm is 2-3x slower
  than native, and draw calls/texture uploads are the expensive operations —
  performance guidance in `other/docs/how-to-improve-lag.md`, pack-size
  guidance in `other/docs/how-to-make-web-exports-lean.md`.

## Verification

- Headless boot check: `--headless --quit-after 60` catches script errors.
  Known pre-existing noise: ~26k TileSet errors from the DGM runtime tile
  builder, and a `recursive_mutex` abort on headless shutdown.
- **Warn before any headless run or export** (boot checks included): the
  owner usually has the editor open, and a second Godot instance sharing
  `.godot/` can destabilise it. Ask, then run.
- **Never `git stash`/`pop` a dirty working tree to compare baselines** —
  it rewrites files under the open editor. Find another way (e.g. read the
  old version from git objects with `git show`).
