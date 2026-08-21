GODOT := /Applications/Godot.app/Contents/MacOS/Godot
PORT := 8060

# CLAUDE: S3 + CloudFront hosting (see planning-make-targets-to-host-game-in-s3-cloudfront.md)
BUCKET := glitcj-godot-core-web
DISTRIBUTION_ID := E2JKFHFOVBMGE0

.PHONY: check export serve deploy invalidate publish game-url

# headless boot check: 60 frames, no window, prints script errors
check:
	$(GODOT) --headless --quit-after 60

# headless release export of the Web preset into build/web/
export:
	$(GODOT) --headless --export-release "Web" build/web/index.html

# serve the web build locally (file:// won't work)
serve:
	cd build/web && python3 -m http.server $(PORT)

# CLAUDE: sync build/web to S3 then bust the CloudFront cache. wasm/pck get
# explicit content types — macOS's MIME database misses .wasm, and a wrong
# Content-Type breaks WebAssembly.instantiateStreaming in the browser.
# CLAUDE: the game now lives under /play/ and site/ (Bugg Studio homepage)
# takes the bucket root. Game goes up first so the homepage never links to
# a missing /play/. The root sync's --delete clears the old root-level game
# files on the first run; --exclude "play/*" keeps it away from the game.
deploy:
	aws s3 sync build/web s3://$(BUCKET)/play/ --delete \
		--exclude "*.import" \
		--exclude "*.wasm" --exclude "*.pck"
	aws s3 cp build/web/index.wasm s3://$(BUCKET)/play/index.wasm \
		--content-type application/wasm
	aws s3 cp build/web/index.pck s3://$(BUCKET)/play/index.pck \
		--content-type application/octet-stream
	aws s3 sync site s3://$(BUCKET)/ --delete --exclude "play/*"
	$(MAKE) invalidate

# CLAUDE: exports always reuse the same index.* filenames, so every deploy
# must invalidate; "/*" counts as one path (first 1000/month are free)
invalidate:
	aws cloudfront create-invalidation \
		--distribution-id $(DISTRIBUTION_ID) --paths "/*"

# export + deploy in one shot
publish: export deploy

game-url:
	@aws cloudfront get-distribution --id $(DISTRIBUTION_ID) \
		--query 'Distribution.DomainName' --output text
