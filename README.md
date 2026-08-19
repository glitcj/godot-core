# godot-core

A reusable game core (Godot 4.7) for building many simple games on shared
infrastructure. See `CLAUDE.md` for architecture notes.

## How to deploy the game

The game is hosted at **https://d2s474u5h6apit.cloudfront.net/**
(S3 + CloudFront — setup details in
`planning-make-targets-to-host-game-in-s3-cloudfront.md`).

Usual flow, exporting from the Godot editor:

1. In the editor: Project > Export... > **Web** preset > Export Project,
   into `build/web/index.html` (the preset's default path).
2. `make deploy` — uploads `build/web/` to S3 and invalidates the
   CloudFront cache.
3. Open the URL and hard-refresh (Cmd+Shift+R). Give the invalidation a
   minute or two to propagate.

Alternative: `make publish` does both steps in one shot (headless export +
deploy) — but it launches a second Godot instance, so don't run it while
the editor is open on this project.

Other targets: `make invalidate` (cache-bust only), `make game-url`
(prints the CloudFront domain).

### AWS architecture

All in account `084250373868`. The bucket is fully private — only the
CloudFront distribution can read it (via the OAC + bucket policy), and
players only ever talk to CloudFront over HTTPS.

| Asset | What it does | Where in the AWS console |
| --- | --- | --- |
| S3 bucket `glitcj-godot-core-web` | Stores the exported web build (`index.html`, `.wasm`, `.pck`, ...) | S3 > Buckets (region us-east-1) > `glitcj-godot-core-web` |
| Bucket policy + Block Public Access | Keeps the bucket private; grants read access only to the distribution | Same bucket > Permissions tab |
| CloudFront distribution `E2JKFHFOVBMGE0` | The CDN serving the game at `d2s474u5h6apit.cloudfront.net`; HTTPS, edge caching, `index.html` as root object | CloudFront > Distributions (global, no region) > `E2JKFHFOVBMGE0` |
| Origin Access Control `E3W5CR7995HXZ1` | Signs CloudFront's requests to S3 so the private bucket accepts them | CloudFront > Security > Origin access, or the distribution's Origins tab |
| Invalidations | Cache-bust records created by `make deploy` | The distribution > Invalidations tab |

### Why the invalidation step

CloudFront caches files at its edge servers so visitors don't hit S3
directly. Since every export reuses the same filenames (`index.pck`,
`index.wasm`, ...), the edges would keep serving the old cached copies
after an upload. An *invalidation* tells CloudFront to throw those copies
away and fetch fresh ones from S3 on the next request. `make deploy` does
this automatically; the first 1000 invalidation paths per month are free,
and ours counts as one.
