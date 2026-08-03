GODOT := /Applications/Godot.app/Contents/MacOS/Godot
PORT := 8060

.PHONY: check export serve

# headless boot check: 60 frames, no window, prints script errors
check:
	$(GODOT) --headless --quit-after 60

# headless release export of the Web preset into build/web/
export:
	$(GODOT) --headless --export-release "Web" build/web/index.html

# serve the web build locally (file:// won't work)
serve:
	cd build/web && python3 -m http.server $(PORT)
