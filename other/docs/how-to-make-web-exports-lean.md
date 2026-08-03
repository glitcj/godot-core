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

This is safe here because the scripts contain **no dynamic `load()`
calls with constructed paths** (verified 2026-08). If any are added
later, their targets must be listed in **Include Filters** on the same
tab, or they will be missing from the pack.

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
