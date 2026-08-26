## Godot gotchas encountered in this project — press F1 and search "_Gotchas".
##
## Documentation-only class: no code, never instantiate. Mirror of
## [code]other/docs/md/how-to-avoid-godot-gotchas.md[/code] (the canonical
## copy — update both when adding entries).
##
## [b]@tool is not inherited.[/b] A script extending a @tool script is NOT a
## tool script — the annotation is per-file. The subclassed node silently stops
## running in the editor: setters don't fire, quantise does nothing, [code]as[/code]
## casts to the class return null. Every script extending the _RPGM_Node family
## needs its own @tool on line 1. Detect offenders via the script resource:
## [codeblock]
## var s : Script = node.get_script()
## if s == null or not s.is_tool():
##     push_warning("%s: script is not @tool" % node.name)
## [/codeblock]
##
## [b]Swapping a node's script can drop its exported values.[/b] Exported
## values live in the .tscn keyed to the node — replace the script and
## overrides can silently vanish (how _common_talker_broken lost its
## map_position). After any script swap, re-check the inspector against git.
##
## [b]Editable-children overrides are path-keyed and break silently.[/b]
## Per-instance edits inside an instanced prefab are stored in the host scene
## as node-path → value diffs. Rename or move a node inside the prefab and
## every instance's override silently reverts to default — no error. Prefer
## exports on the prefab root that forward to children:
## [codeblock]
## @export var messages : Array = []:
##     set(v):
##         messages = v
##         if talker_script: talker_script.messages = v
## [/codeblock]
##
## [b]:= can't infer from untyped functions.[/b] [code]var p := get_player()[/code]
## is a compile error if the getter has no declared return type. Type the
## variable explicitly, or annotate the getter's return type.
##
## [b]Signals and coroutines still fire on disabled nodes.[/b]
## PROCESS_MODE_DISABLED stops _process/physics/input — NOT signal delivery or
## resume-pending coroutines. A removed/suspended node's signal-driven triggers
## still run unless explicitly gated (see _RPGM_Script._wrapped_callable's
## Removed check). Same reason audio keeps playing on suspended viewports.
##
## [b]A while-true coroutine is "running" forever.[/b] A trigger that never
## returns (ghost patrol loop) keeps any is-it-running flag latched
## permanently. Anything gating on "no script running" — like can_save() —
## must filter to scripts that actually block:
## [codeblock]
## if s.interrupt_player and s.is_running(): return false
## [/codeblock]
##
## [b]@export_tool_button + typed Callable = Nil errors on script save.[/b]
## Callables can't be snapshotted, so editor hot-reload restores them as Nil —
## assigning Nil to a ": Callable"-typed var prints an error per instance.
## Harmless but noisy; leave the var untyped:
## [codeblock]
## @export_tool_button("Quantise") var call_quantise = _quantise_position
## [/codeblock]
##
## [b]JSON round-trips mangle types.[/b] JSON.parse_string returns floats for
## every number and knows nothing about Vector2i — store vectors as x/y arrays
## and cast ints back on load:
## [codeblock]
## "map_position": [p.map_position.x, p.map_position.y]      # save
## Vector2i(int(d.map_position[0]), int(d.map_position[1]))  # load
## [/codeblock]
##
## [b]"in" checks properties on objects, keys on dictionaries.[/b]
## [code]"messages" in node[/code] asks "does a property/method with this name
## exist"; [code]"messages" in dict[/code] asks "is this a key". For known
## classes prefer the typed cast — the check plus type safety:
## [codeblock]
## var event := get_parent() as _RPGM_Event
## if event: event.state = _RPGM_Event.EventState.B  # null instead of crash
## [/codeblock]
##
## [b]user:// on web is IndexedDB.[/b] Real file on desktop (macOS:
## ~/Library/Application Support/Godot/app_userdata/<project>/), IndexedDB in
## the browser. Web flushes asynchronously — a save made the instant the tab
## closes can be lost; save at deliberate moments. Per-browser, wiped by
## "clear site data".
##
## [b]res:// paths are case-sensitive in web exports.[/b] macOS hides casing
## mismatches; the web export does not. A load() that works locally 404s in
## the browser. Match file casing exactly, always.
class_name _Gotchas
extends Object
# CLAUDE: documentation-only class — exists so the gotchas doc renders in the
# editor's built-in Help (F1 -> "_Gotchas"). Canonical source is the .md in
# other/docs/md/; keep the two in sync when adding entries.
