# Plan: leaner web export and serving

The deployed game is ~420 MB per fresh visitor (`index.pck` 382 MB,
`index.wasm` 39 MB) served from S3 + CloudFront (see repo-root
`planning-make-targets-to-host-game-in-s3-cloudfront.md`). This plan covers
cutting that down, on both the export side and the serving side.

Measured 2026-08-19: `assets/` is 623 MB on disk — rpgmaker 280 MB,
skies 93 MB, ninja 62 MB, basic_3d_models 52 MB, doomer 44 MB,
proto_zelda 36 MB, basic_3d_guns 32 MB, the rest under 12 MB each.
All `.wav` files together are only 5.4 MB, so audio re-compression is a
minor lever now, not a major one.

## Export side (shrinks the pck itself)

### 1. Dependency-based export — the big lever

The Web preset uses export mode "all resources", so the pck packs the whole
project including every untouched corner of every asset pack. Switching to
**"Export selected scenes (and dependencies)"** with only `_core.tscn`
ticked packs just what the dependency graph reaches.

Full instructions and the safety caveat (no dynamic `load()` with
constructed paths — verified safe 2026-08, must re-verify if added later)
are in `how-to-make-web-exports-lean.md`. Do this first and re-measure;
it decides whether anything below is worth doing.

Expected outcome: the unused bulk of `assets/rpgmaker/` (280 MB source,
only a handful of tilesets/parallaxes used) and unreferenced parts of the
other packs drop out automatically. This answers the "not sure we're using
all those assets" doubt without manually auditing folders — the dependency
walk *is* the audit.

### 2. Only if still too big after step 1

- Texture import sizes: PNGs ship as imported `.ctex` sized by import
  settings. Downscaling oversized source art (4K skyboxes, huge
  parallaxes) at import shrinks the pck without touching source files.
- Audio: 62 wavs = 5.4 MB total. Skip unless chasing the last few MB.

## Serving side (shrinks bytes over the wire, pck unchanged)

### 3. Pre-compressed wasm upload

CloudFront only auto-compresses objects up to 10 MB, so the 39 MB wasm is
served raw. Gzipping it locally gets it to **10 MB** (measured). The fix:
upload a gzipped copy with the encoding declared, in the `deploy` target:

```sh
gzip -9 -c build/web/index.wasm > /tmp/index.wasm.gz
aws s3 cp /tmp/index.wasm.gz s3://$(BUCKET)/index.wasm \
	--content-type application/wasm --content-encoding gzip
```

Browsers decompress transparently (all wasm-capable browsers accept gzip).
Saves ~29 MB per fresh visitor for one extra deploy step.

### 4. Maybe: pre-compressed pck

Same trick works for the pck, but its contents (`.ctex` textures) are
already compressed, so gains are uncertain — measure
`gzip -c build/web/index.pck | wc -c` after step 1 shrinks it, and only
adopt if the ratio is worthwhile. Note gzip of a multi-hundred-MB file
adds real time to every deploy.

### 5. Minor: Cache-Control on upload

S3 objects currently carry no `Cache-Control`, so browsers use heuristic
caching and revalidate via ETag. Adding
`--cache-control "public, max-age=31536000"` to the uploads makes repeat
visits fully cache-hit with zero requests. Safe *only because* every
deploy invalidates CloudFront `/*` — returning players may still need the
hard-refresh they already do today.

## Order of operations

1. Step 1 (export mode), re-export from the editor, compare pck size,
   play through every scene at the CloudFront URL.
2. Step 3 (gzipped wasm) — independent of step 1, small Makefile change.
3. Re-measure; only then decide on steps 2, 4, 5.

## Best practice moving forward

- **Keep the export dependency-driven, not filter-driven.** Exclude
  filters rot as packs get reused; the dependency walk from `_core.tscn`
  stays correct as scenes come and go. Its one rule: never `load()` a
  constructed path without adding the target to the preset's Include
  Filters.
- **Check the pck number after every export.** It prints in the export
  output and sits in `build/web/`. A sudden jump means a new dependency
  dragged a whole pack in — cheapest to catch immediately, while you know
  which scene caused it.
- **When adding an asset pack, import only what's needed** — or at least
  note in the pack folder what's actually used. The 623 MB `assets/`
  folder is fine for the repo, but every file referenced from a reachable
  scene becomes payload.
- **Watch source art dimensions at import time.** A 4096px texture that
  renders at 512px is pure pck bloat; set the import-time size limit when
  the asset lands, not during a later cleanup.
- **Prefer ogg for anything longer than a stinger.** Wavs are fine for
  short SFX; music and ambience should land as ogg from the start.
- **Egress math to keep in mind:** every fresh visitor downloads the full
  build. At today's 420 MB the AWS free tier (1 TB/month) covers ~2,400
  first plays; a 100 MB build covers ~10,000. Leanness is capacity, not
  just load time.
