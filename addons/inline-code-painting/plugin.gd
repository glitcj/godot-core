@tool
extends EditorPlugin


# i0i what is this plugin ?
# this plugin will allow code painting to be easier
# from within the godot editor directly
# currently the way the dev works is:
# 1. write o-blah claude painting comments in any file
# 2. use the copy-with-path plugin to grab the lines and context and filename etc
# 3. pastes it in an active claude cli chat session
# 4. claude updates the file the dev copied lines from, and code painting continues

# i0i the context switching of copying the pasting into a separate
# terminal window is slow and costly, instead, this pluging will allow the
# to simply press F1 or F2 or similar, and all the line from the current
# script file are sent to an active claude session, which then edits the file
# and code painting continues. Ideally this whole flow can happen in the editor, 
# and ideally the claude session can be active throughout so it does not lose
# context as the dev continues code painting with the agent.


# CLAUDE: first version of the plugin — Cmd+Option+P sends the current
# script to a headless claude session, resumed on every press so the
# agent keeps its context between paints

const PAINT_KEY := KEY_P
const CLAUDE_BINARY_PATH_IN_HOME := ".local/bin/claude"
const CLAUDE_CONFIG_DIRECTORY_IN_HOME := ".claude-glitcj"
const CLAUDE_ALLOWED_TOOLS := ["Read", "Edit"]
# CLAUDE: explicit overrides — these win over ~/.claude-glitcj/settings.json
# for paint runs only, so the model and effort are picked here
# model aliases: fable, opus, sonnet, haiku
const CLAUDE_MODEL := "fable"
# effort levels: low, medium, high, xhigh, max
const CLAUDE_EFFORT := "medium"
const CLAUDE_PERMISSION_MODE := "acceptEdits"

var claude_thread: Thread
var claude_session_id := _new_claude_session_id()
var claude_session_started := false
var painted_code_edit: CodeEdit

# :Q: is this plugin working ?
# :A: yes, this answer arrived through the plugin itself.
# the key press reached claude and the edit landed.

# :Q: seems like it worked the first time ! just checking again
# :A: works again, and the session was resumed.
# claude still remembers the first paint.


# :Q: if i highlight one part of the file, will
# it paint replying to all paint comments ? or just the highlighted one ?
# :A: just the highlighted one, the prompt carries the line range.
# the o-ask on line 49 was left unanswered as proof.

# :Q: how does it remember the session ? will the session
# reset after everytime i restart claude ?
# :A: claude_session_id is made once when the plugin loads,
# then every press passes it to claude with --resume.
# :A: it resets when the editor or this plugin restarts,
# your own claude terminal sessions do not affect it.


# :Q: what are the default claude settings used ?
# can u include the settings here e.g. to pick the model
# used and so on
# :A: none are set here, claude reads ~/.claude-glitcj/settings.json,
# so the model is whatever that config defaults to.
# :A: only acceptEdits and the Read and Edit tools are forced.
# :A: yes, a CLAUDE_MODEL const passed as "--model" would pick it.


# :C: Cmd+Option+P paints the script that has focus.
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo: return
	if key.physical_keycode != PAINT_KEY or not key.meta_pressed or not key.alt_pressed: return
	if claude_thread != null: return

	var script_editor := EditorInterface.get_script_editor()
	var script := script_editor.get_current_script()
	var current_editor := script_editor.get_current_editor()
	if script == null or current_editor == null: return
	var code_edit := current_editor.get_base_editor() as CodeEdit
	if code_edit == null or not code_edit.has_focus(): return

	get_viewport().set_input_as_handled()
	# :C: claude reads the file from disk,
	# so unsaved edits would be invisible to it.
	script_editor.save_all_scripts()
	_start_paint(code_edit, _build_paint_prompt(script, code_edit))


# :C: claude reads the file itself,
# so only the path and line range are sent.
func _build_paint_prompt(script: Script, code_edit: CodeEdit) -> String:
	var script_path := ProjectSettings.globalize_path(script.resource_path)
	var line_range := ""
	if code_edit.has_selection():
		line_range = " (only lines %d-%d)" % [
			code_edit.get_selection_from_line() + 1,
			code_edit.get_selection_to_line() + 1,
		]
	return (
		"Code painting request from the Godot editor. "
		+ "Handle the code painting comments (o- flags) in %s%s " % [script_path, line_range]
		+ "following the Code Painting rules in CLAUDE.md. Reply in one short line."
	)


# :C: /bin/sh changes into the project root first,
# so claude loads the project's CLAUDE.md.
# :C: absolute binary path, because a GUI-launched Godot
# has no ~/.local/bin on its PATH.
func _build_claude_arguments(paint_prompt: String) -> PackedStringArray:
	var home_directory := OS.get_environment("HOME")
	var session_flag := "--resume" if claude_session_started else "--session-id"
	var claude_arguments: PackedStringArray = [
		"-c", 'cd "$1" && shift && exec "$@"', "sh",
		ProjectSettings.globalize_path("res://"),
		"/usr/bin/env",
		"CLAUDE_CONFIG_DIR=%s/%s" % [home_directory, CLAUDE_CONFIG_DIRECTORY_IN_HOME],
		"%s/%s" % [home_directory, CLAUDE_BINARY_PATH_IN_HOME],
		"-p", paint_prompt,
		session_flag, claude_session_id,
		"--model", CLAUDE_MODEL,
		"--effort", CLAUDE_EFFORT,
		"--permission-mode", CLAUDE_PERMISSION_MODE,
		"--allowedTools",
	]
	claude_arguments.append_array(PackedStringArray(CLAUDE_ALLOWED_TOOLS))
	# CLAUDE: escape every argument — OS.execute with an output array
	# pastes the arguments into one double-quoted shell command, which
	# expanded "$1" and "$@" to nothing, so claude was never started
	for argument_index in claude_arguments.size():
		claude_arguments[argument_index] = _escape_for_double_quotes(claude_arguments[argument_index])
	return claude_arguments


# :C: these four characters stay special inside double quotes.
func _escape_for_double_quotes(argument: String) -> String:
	for special_character in ["\\", '"', "$", "`"]:
		argument = argument.replace(special_character, "\\" + special_character)
	return argument


# :C: read-only while claude runs,
# so typing cannot conflict with claude's edit.
func _start_paint(code_edit: CodeEdit, paint_prompt: String) -> void:
	painted_code_edit = code_edit
	painted_code_edit.editable = false
	print("[paint] painting…")
	claude_thread = Thread.new()
	claude_thread.start(_run_claude.bind(_build_claude_arguments(paint_prompt)))


# :C: OS.execute blocks until claude exits,
# so it runs on a thread to keep the editor responsive.
func _run_claude(claude_arguments: PackedStringArray) -> void:
	var claude_output: Array = []
	var exit_code := OS.execute("/bin/sh", claude_arguments, claude_output, true)
	_on_claude_finished.call_deferred(exit_code, "".join(claude_output).strip_edges())


# :C: runs on the main thread, via call_deferred.
func _on_claude_finished(exit_code: int, claude_output: String) -> void:
	claude_thread.wait_to_finish()
	claude_thread = null
	if is_instance_valid(painted_code_edit): painted_code_edit.editable = true
	# :C: the session id only exists for --resume
	# once a first run has succeeded.
	if exit_code == 0: claude_session_started = true
	if exit_code == 0: print("[paint] ", claude_output)
	else: push_error("[paint] claude exited with code %d: %s" % [exit_code, claude_output])
	# CLAUDE: deferred — reloading plugin.gd itself while this
	# function was still running crashed the editor
	EditorInterface.get_script_editor().reload_open_files.call_deferred()


# :C: a thread must be joined before it is freed.
func _exit_tree() -> void:
	if claude_thread != null: claude_thread.wait_to_finish()


# :C: claude only accepts a valid UUID as session id,
# and GDScript has no built-in generator.
func _new_claude_session_id() -> String:
	var random_bytes := Crypto.new().generate_random_bytes(16)
	random_bytes[6] = (random_bytes[6] & 0x0f) | 0x40
	random_bytes[8] = (random_bytes[8] & 0x3f) | 0x80
	var hex := random_bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4),
		hex.substr(16, 4), hex.substr(20, 12),
	]
