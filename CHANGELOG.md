# Changelog

Notable changes to the core. Newest first.

## 2026-08-03

- **Inactive scenes are now fully frozen** — `_Core_Viewport` gained
  `_suspend()` / `_resume()` (SubViewport `UPDATE_DISABLED` +
  `PROCESS_MODE_DISABLED`); scenes boot suspended. Policy sits in `_Core`:
  `change_viewport` suspends the outgoing scene, while `add_viewport` /
  `remove_viewport` keep the stacked background scene running (refined by
  hand after the first version froze overlays). Removed the constant lag
  from all six scenes rendering and processing simultaneously.
- **Portrait frame cache** — `_RPGM_Portrait._update_atlas()` now caches
  extracted frames in a static Dictionary shared by all portraits instead
  of decompressing the spritesheet and uploading a new `ImageTexture` on
  every animation tick of every portrait. Removed most of the remaining
  RPGM-scene lag on web.
- **Docs**: `other/docs/how-to-improve-lag.md` (web perf findings: portrait
  texture churn, double 1080p viewport chain, per-portrait materials),
  `other/docs/how-to-make-web-exports-lean.md` (dependency-based export,
  audio import compression).
- **CLAUDE.md** — repo purpose, Claude working rules (small reviewed
  changes, `# CLAUDE:` comments), architecture notes, export workflow.
- **CHANGELOG.md** — this file.

## 2026-08-02

- **First web export** — Godot 4.7 export templates installed, "Web" preset
  created in `export_presets.cfg` (thread support off so the build runs on
  any static host without COOP/COEP headers; later recreated by hand via
  the editor). Exports to `build/web/` (added to `.gitignore`).
  First build: ~364MB pck + 38MB wasm, served locally with
  `python3 -m http.server`.
- **Doc**: `how-to-build-and-host-project-in-html.md` (repo root) — export
  templates, preset, build, local serve, publish targets, gotchas.
