# How to improve lag (web builds)

Findings from profiling the RPGM scene on the web export (2026-08).
Background: the web build renders on the Compatibility renderer (WebGL2),
wasm runs 2-3x slower than native, and every draw call / texture upload
goes through ANGLE (GL -> Metal translation), which makes state changes
and uploads the expensive operations. Design 2D scenes accordingly.

## Freezing inactive scenes (done)

All `_Core_Viewport` scenes suspend when not current: `_suspend()` sets
the SubViewport to `UPDATE_DISABLED` and the container to
`PROCESS_MODE_DISABLED`; `_resume()` reverses both. Policy lives in
`_Core`: `change_viewport` suspends the old scene, `add_viewport` keeps
the stacked scene running. This removed most of the constant lag.

Caveats: audio keeps playing through a suspended branch (stop it in
`_on_viewport_finish`); a suspended scene resumes exactly where it froze.

## RPGM scene: remaining causes, ranked

### 1. Portrait texture churn (biggest)

`_rpgm_portrait.gd :: _update_atlas()` is connected to the sampler's
`frame_changed`. Every animation tick, for every portrait (20 in the
map), it decompresses the whole spritesheet (`get_image()`), crops one
frame, and uploads a brand-new `ImageTexture`. Constant CPU + upload
stutter on web.

**Fix:** cache extracted frames in a Dictionary keyed by
`animation + frame index` (lazily on first use, or precompute in
`_ready`). After warm-up, `_update_atlas` just swaps cached textures.

**Verify first:** comment out
`%_sampler.frame_changed.connect(_update_atlas)`, re-export, compare.
If the stutter disappears, this is confirmed.

### 2. Double full-HD viewport chain

`_rpgm.tscn` nests two 1920x1080 SubViewports, both
`render_target_update_mode = ALWAYS`, both `transparent_bg` — the map
renders to one HD target, is alpha-composited into a second, then drawn
to screen (~3 fullscreen fill passes per frame). The 3D scenes use a
single viewport, which is why they feel smoother.

**Fixes, cheapest first:** disable `transparent_bg` where see-through
isn't needed; render the inner viewport at low res (e.g. 640x360) and
scale up — right look for pixel art, ~85% fill saved; flatten the chain
if the inner viewport is only for layout.

### 3. Per-portrait ShaderMaterials

Each portrait creates its own `ShaderMaterial` + `NoiseTexture2D`, so
nothing batches: 20 draw calls with shader switches. Share one material
instance per shader `type` instead of `ShaderMaterial.new()` per
portrait.

## General web levers (when needed)

- Always profile the **release** export, devtools closed; the editor's
  Run-in-Browser button ships a debug build and lies about performance.
- Strip expensive rendering features per-platform with the `web`
  feature tag (project setting overrides), keeping them on desktop.
- Thread support is off in the export preset (runs on any static host);
  re-enabling it needs COOP/COEP headers from the host but restores
  real multithreading.
