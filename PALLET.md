# PALLET

Copy-paste command palette for this repo. Make targets in brackets.

## Headless runs

Godot binary:

```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
```

Boot check — runs the game 60 frames with no window, prints script
errors, quits. Close the editor first (two instances share `.godot/`):

```bash
$GODOT --headless --quit-after 60          # [make check]
```

Export the web build (release) to `build/web/`:

```bash
$GODOT --headless --export-release "Web" build/web/index.html   # [make export]
```

Known noise in headless output: ~26k TileSet errors from the DGM runtime
tile builder, and a `recursive_mutex` abort on shutdown. Both pre-date
2026-08 and are not caused by your change.

## Host the web game

Locally (file:// won't work — must be served over HTTP):

```bash
cd build/web && python3 -m http.server 8060   # [make serve]
# open http://localhost:8060
```

After every re-export: hard-refresh the browser (Cmd+Shift+R) — the
pck/wasm cache aggressively.

Publish: upload the contents of `build/web/` to itch.io (zip it, HTML
project) or any static host — works without special headers because the
preset has thread support off. Full guide:
`how-to-build-and-host-project-in-html.md`.
