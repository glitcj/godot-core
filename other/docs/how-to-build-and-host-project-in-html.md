# How to build and host this project in HTML

Godot's Web export compiles the game to WebAssembly. The output is three main
files — `index.html`, `index.wasm` (the engine), and `index.pck` (all game
data) — plus a few support scripts. Any static web host can serve them.

## One-time setup

1. **Install export templates** (once per Godot version):
   Editor → **Manage Export Templates** → **Download and Install** (~1GB).
   They install to `~/Library/Application Support/Godot/export_templates/`.

2. **Create the Web preset**:
   Project → **Export…** → **Add…** → **Web**.
   - Set the export path to `build/web/index.html` (`build/` is gitignored).
   - Under **Variant**, turn **Thread Support off** — the build then runs on
     any plain static host without special HTTP headers. (Keep it on only if
     the host sends `Cross-Origin-Opener-Policy: same-origin` and
     `Cross-Origin-Embedder-Policy: require-corp`.)

## Build

From the Export dialog: **Export Project…** → uncheck **Export With Debug**.

Or from the terminal, without opening the editor:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --export-release "Web" build/web/index.html
```

## Run locally

Browsers refuse to run the build from a `file://` path — it must be served
over HTTP:

```bash
cd build/web
python3 -m http.server 8060
# open http://localhost:8060
```

Shortcut while iterating: the **browser icon** in the editor's top-right
toolbar (Remote Debug → Run in Browser) exports a debug build, serves it, and
opens the browser in one click.

## Publish

Upload the contents of `build/web/` to any static host:

- **itch.io** — zip the folder, upload as an HTML project. Easiest.
- **GitHub Pages / Netlify / Cloudflare Pages** — push the folder as-is
  (works because Thread Support is off).

## Gotchas

- **Hard-refresh after every rebuild** (Cmd+Shift+R). The `.pck` and `.wasm`
  are cached aggressively; a stale cache causes version-mismatch errors.
- **Pack size**: the export bundles *every* resource in the project — the
  full `assets/` folder ships even if unused (~364MB currently). Before
  publishing, add exclude filters in the preset's **Resources** tab
  (e.g. `assets/rpgmaker/*`) to drop unused packs.
- **Case sensitivity**: `res://` paths that work on macOS can 404 in the web
  build if the file-name casing doesn't match exactly.
- **Renderer**: the web build uses the Compatibility (WebGL2) renderer, not
  Forward+ — visuals and performance differ from the editor.
- **Audio** won't start until the player clicks the page once (browser
  autoplay rule, not a bug).
