# Plan: make targets to host the web build in S3 + CloudFront

Goal: `make deploy` pushes `build/web/` to an S3 bucket, and the game is
playable at a CloudFront URL over HTTPS.

## Status: DONE (implemented 2026-08-19)

- Bucket: `glitcj-godot-core-web` (us-east-1, fully private)
- OAC id: `E3W5CR7995HXZ1`
- Distribution: `E2JKFHFOVBMGE0`
- **Game URL: https://d2s474u5h6apit.cloudfront.net/**
- Makefile has `deploy`, `invalidate`, `publish`, `game-url` targets.

## Current state (verified 2026-08-19)

- AWS CLI is configured and working: account `084250373868`, region
  `us-east-1`. **Caveat: these are root-account credentials.** Everything
  below works with them, but the safer setup is an IAM user with a policy
  scoped to this one bucket + distribution. Not a blocker — noted for later.
- `Makefile` already has `check`, `export`, `serve`. The new targets slot in
  next to them.
- The Web export preset has `thread_support=false`, so the build does **not**
  need the `Cross-Origin-Opener-Policy` / `Cross-Origin-Embedder-Policy`
  headers. That means a plain CloudFront distribution works — no response
  headers policy needed. (If threads are ever enabled, revisit: add a
  CloudFront Response Headers Policy setting COOP `same-origin` and COEP
  `require-corp`.)
- Current build size: `index.pck` is **382 MB**, `index.wasm` 39 MB — about
  420 MB total per fresh visitor. See "Costs" and the lean-exports doc.

## Architecture

Private S3 bucket + CloudFront with **Origin Access Control (OAC)**.

- The bucket stays fully private (Block Public Access on). Only CloudFront
  can read it, via a bucket policy keyed to the distribution ARN.
- No S3 "static website hosting" mode — that's the legacy approach and
  requires a public bucket with HTTP-only origin. OAC is the current
  recommended setup and gives HTTPS end-to-end.
- CloudFront serves `index.html` as the default root object, so the game
  loads at `https://<dist-id>.cloudfront.net/` directly.
- No custom domain in scope for now. If added later: ACM cert must be in
  `us-east-1` (already the configured region), plus a Route 53 / DNS alias.

## One-time setup (Phase 1)

These run once, by hand or via a `make s3-setup` convenience target. Suggested
names — adjust to taste:

- Bucket: `glitcj-godot-core-web` (bucket names are global; may need a suffix)
- Region: `us-east-1`

Steps:

1. **Create bucket**, block all public access:
   ```sh
   aws s3api create-bucket --bucket glitcj-godot-core-web --region us-east-1
   aws s3api put-public-access-block --bucket glitcj-godot-core-web \
   	--public-access-block-configuration \
   	BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
   ```
2. **Create an Origin Access Control** (`aws cloudfront create-origin-access-control`)
   with signing behavior `always`, protocol `sigv4`, origin type `s3`.
3. **Create the distribution** (`aws cloudfront create-distribution`) with:
   - Origin: `glitcj-godot-core-web.s3.us-east-1.amazonaws.com` + the OAC id.
   - Default root object: `index.html`.
   - Viewer protocol policy: `redirect-to-https`.
   - Cache policy: `CachingOptimized` (managed policy
     `658327ea-f89d-4fab-a63d-7e88639e58f6`).
   - Compression on (only helps files < 10 MB — html/js; the wasm and pck
     are served uncompressed regardless).
   - Cheapest price class (`PriceClass_100`) is fine for personal use.
4. **Bucket policy** allowing that distribution to read:
   ```json
   {
   	"Version": "2012-10-17",
   	"Statement": [{
   		"Effect": "Allow",
   		"Principal": {"Service": "cloudfront.amazonaws.com"},
   		"Action": "s3:GetObject",
   		"Resource": "arn:aws:s3:::glitcj-godot-core-web/*",
   		"Condition": {"StringEquals": {
   			"AWS:SourceArn": "arn:aws:cloudfront::084250373868:distribution/<DIST_ID>"
   		}}
   	}]
   }
   ```
5. Record the distribution id and domain in the Makefile variables below.

The distribution takes ~5–15 minutes to deploy the first time.

## Makefile additions (Phase 2)

Variables at the top, next to `GODOT` / `PORT`:

```make
BUCKET := glitcj-godot-core-web
DISTRIBUTION_ID := <filled in after Phase 1>
```

Targets:

```make
.PHONY: deploy invalidate publish game-url

# sync build/web to S3; --delete removes stale files from old exports
deploy:
	aws s3 sync build/web s3://$(BUCKET)/ --delete \
		--exclude "*.import" \
		--exclude "*.wasm" --exclude "*.pck"
	aws s3 cp build/web/index.wasm s3://$(BUCKET)/index.wasm \
		--content-type application/wasm
	aws s3 cp build/web/index.pck s3://$(BUCKET)/index.pck \
		--content-type application/octet-stream
	$(MAKE) invalidate

# every deploy replaces files in place, so bust the CloudFront cache
invalidate:
	aws cloudfront create-invalidation \
		--distribution-id $(DISTRIBUTION_ID) --paths "/*"

# export + deploy in one shot
publish: export deploy

game-url:
	@aws cloudfront get-distribution --id $(DISTRIBUTION_ID) \
		--query 'Distribution.DomainName' --output text
```

Notes on the choices:

- **`.wasm` and `.pck` are uploaded with explicit `--content-type`.**
  `aws s3 sync` guesses MIME types from the OS database; macOS often doesn't
  know `.wasm`, and a wrong `Content-Type` on the wasm breaks
  `WebAssembly.instantiateStreaming` in the browser. Two explicit `cp` calls
  are the simplest reliable fix.
- **`--exclude "*.import"`** — the export folder contains Godot `.import`
  metadata for the icon PNGs; no reason to serve them.
- **Invalidation `"/*"`** — filenames never change between exports (always
  `index.*`), so the CloudFront cache must be invalidated on every deploy.
  `/*` counts as one path; the first 1000 paths/month are free, so this
  costs nothing at this scale. (The alternative — versioned filenames — isn't
  worth fighting Godot's fixed export naming for.)
- Uploads of the 382 MB pck use the CLI's automatic multipart upload; expect
  the deploy to take a few minutes depending on uplink.

## Costs (rough)

- S3 storage: ~420 MB ≈ **$0.01/month**.
- CloudFront egress: ~$0.085/GB → a fresh visitor downloading the full build
  costs **~$0.04 per first play** (repeat plays hit the browser cache).
  AWS free tier currently includes 1 TB/month of CloudFront egress, which
  covers ~2,400 fresh plays/month for free.
- The real lever is pck size — `other/docs/how-to-make-web-exports-lean.md`
  applies directly here.

## Verification

1. `make publish`, wait for the invalidation to complete (~1–2 min).
2. Open `https://$(make game-url)/` in a normal window, then hard-refresh
   (Cmd+Shift+R) — same pck/wasm caching caveat as local testing.
3. Check the browser console for MIME/CORS errors on `index.wasm`.

## Out of scope for now

- Custom domain + ACM certificate.
- IAM user with scoped deploy-only policy (recommended follow-up given the
  root credentials).
- Pre-compressed (gzip/brotli) uploads of wasm/pck with `Content-Encoding` —
  would cut transfer ~30–50% but complicates the deploy; revisit if egress
  cost or load time becomes a problem.
