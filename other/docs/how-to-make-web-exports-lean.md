# How to make web exports lean

The web export currently packs every resource in the project
(`index.pck` ~364MB) because the preset's export mode is
"all resources". Almost every pack under `assets/` is referenced by
*something* (rpgmaker x20, ninja, skies, doomer, proto_zelda, the
basic_3d packs...), so folder exclude-filters can't safely cut the
bulk. Dependency-based export can.

## 1. Export only what _core.tscn reaches

Project -> Export -> Web preset -> **Resources** tab ->
Export Mode: **"Export selected scenes (and dependencies)"** ->
tick only `_core.tscn`.

Godot walks the dependency graph from the main scene and packs only
reachable files. The unused bulk of `assets/rpgmaker/` (280MB, of which
only a handful of tilesets/parallaxes are used) and every untouched
pack drop out automatically.

<!-- CLAUDE: corrected 2026-08-19 — the earlier "no dynamic load() calls"
claim was wrong and this mode broke the build (grey screen at boot).
The dependency walk misses two reference kinds this project uses heavily:
class_name references (51 files) and runtime load() calls
(_rpgm_portrait.gd shaders). -->
**The walk only follows path-based references** — `ext_resource` in
scenes and `preload()` in scripts. It misses:

- **`class_name` references** (`extends _Core_Viewport`,
  `_Core_Tweener.new()`) — resolved via the global class registry, no
  path recorded. This project uses them in ~51 files; without a fix the
  base scripts are dropped and the game grey-screens at boot.
- **Runtime `load()` calls**, even with literal paths — e.g. the twelve
  shader loads in `viewports/rpgm/components/_rpgm_portrait.gd`.
- **Cascades**: a dropped script's `preload()`s drop with it
  (`_core_templates.gd` → `core/window/_core_window.tscn`).

So step 1 requires **Include Filters** on the same Resources tab:

```
*.gd, *.gdshader
```

Scripts and shaders are tiny, so this costs almost nothing.

<!-- CLAUDE: added 2026-08-19 after the include-filter fix still broke
rpgm — _core_templates.gd's preload of _core_window.tscn wasn't walked,
and the window scene's own texture was missing too. -->
Include filters only match files — they do **not** walk the matched
files' dependencies. So a scene that is only ever `preload()`ed from a
script must be **ticked in the export tree** next to `_core.tscn`;
ticked scenes get the full dependency walk (their textures come along).
Filter-including such a scene ships it without its ext_resources, and a
scene missing any ext_resource fails to load entirely. Currently ticked:
`core/window/_core_window.tscn`, `viewports/birds/_core_log_item.tscn`,
`viewports/dgm/_dgm_tile.tscn`.

Rule of thumb: filters for leaf files (scripts, shaders); ticks for
anything with dependencies of its own. Any remaining miss fails loudly
at runtime (see Verify) naming the file.

## 2. Verify

Re-export, compare `index.pck` size, then play through every scene.
Anything unreachable by the dependency walk fails loudly with a
missing-resource error naming the file — add it to Include Filters.
Web builds are case-sensitive about `res://` paths (macOS hides
mismatches), so treat any unexpected miss as a casing bug first.

## 3. Audio imports

62 `.wav` files import as uncompressed PCM. For music/ambience that is
enormous. Select them in the FileSystem dock -> Import tab -> set
compress mode (QOA), or convert long tracks to Ogg. Short SFX can stay
uncompressed.

## 4. What not to bother with

- `index.wasm` (38MB) is fixed engine cost; hosts serve it gzipped
  (~10MB over the wire) — itch.io and GitHub Pages do this
  automatically.
- Source files that Godot doesn't import (`.fbx` sources, `.aseprite`)
  are not packed anyway; PNGs ship as imported `.ctex`, sized by their
  import settings, not the source file.

## Order of operations

Do step 1 alone and check the pck number first — it is the big lever
and tells you whether the audio pass is worth the effort.
