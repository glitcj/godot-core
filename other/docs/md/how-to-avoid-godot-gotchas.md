# How to avoid Godot gotchas

Running list of Godot behaviours that bit us (or nearly did). Keep entries
short: a few sentences + a snippet. Add new ones at the bottom as found.

This file is the canonical copy. It is mirrored as a documentation-only class
in `other/docs/gd/_gotchas.gd` so it renders in the editor's built-in Help —
press F1 and search `_Gotchas`. Update both when adding an entry.

## `@tool` is not inherited

A script extending a `@tool` script is NOT a tool script — the annotation is
per-file. The subclassed node silently stops running in the editor: setters
don't fire, quantise does nothing, `as` casts to the class return null.
Every script extending anything in the `_RPGM_Node` family needs its own
`@tool` on line 1. Detect offenders via the script resource:

```gdscript
var s : Script = node.get_script()
if s == null or not s.is_tool():
	push_warning("%s: script is not @tool" % node.name)
```

## Swapping a node's script can drop its exported values

Exported values live in the .tscn keyed to the node — replace the script and
overrides can silently vanish (this is how `_common_talker_broken...` lost
`map_position = (-1, 0)`). After any script swap, re-check the node's
inspector against git.

## Editable-children overrides are path-keyed and break silently

Per-instance edits inside an instanced prefab are stored in the *host* scene
as `node-path → value` diffs. Rename/move a node inside the prefab and every
instance's override silently reverts to the default — no error. Prefer
exports on the prefab **root** that forward to children; then instances never
need editable children:

```gdscript
@export var messages : Array[String] = []:
	set(v):
		messages = v
		if talker_script: talker_script.messages = v
```

## `:=` can't infer from untyped functions

`var p := get_player()` is a compile error if `get_player()` has no declared
return type. Either type the variable explicitly or annotate the getter:

```gdscript
var p : _RPGM_Player = get_player()      # or:
func get_player() -> _RPGM_Player: ...
```

## Signals and coroutines still fire on disabled nodes

`PROCESS_MODE_DISABLED` stops `_process`/physics/input — it does NOT stop
signal delivery or resume-pending coroutines. A "removed"/suspended node's
signal-driven triggers still run unless explicitly gated (see
`_RPGM_Script._wrapped_callable`'s Removed check). Same reason audio keeps
playing on suspended viewports.

## A `while true` coroutine is "running" forever

A trigger that never returns (ghost patrol loop) keeps any is-it-running
flag latched permanently. Anything gating on "no script is running" —
like `can_save()` — must filter to scripts that actually block
(`interrupt_player`), or it will never pass:

```gdscript
if s.interrupt_player and s.is_running(): return false
```

## `@export_tool_button` + typed Callable = Nil errors on script save

Callables can't be snapshotted, so the editor's script hot-reload restores
them as Nil — assigning Nil to a `: Callable`-typed var prints an error per
instance. Harmless but noisy; leave the var untyped:

```gdscript
@export_tool_button("Quantise") var call_quantise = _quantise_position  # no ": Callable"
```

## JSON round-trips mangle types

`JSON.parse_string` returns floats for every number and knows nothing about
Vector2i — store vectors as `[x, y]` arrays and cast ints back on load:

```gdscript
"map_position": [p.map_position.x, p.map_position.y]      # save
Vector2i(int(d.map_position[0]), int(d.map_position[1]))  # load
```

## `in` checks properties on objects, keys on dictionaries

`"messages" in node` asks "does a property/method with this name exist" —
`"messages" in dict` asks "is this a key". Easy to conflate. For known
classes prefer the typed cast, which is the check plus type safety:

```gdscript
var event := get_parent() as _RPGM_Event
if event: event.state = _RPGM_Event.EventState.B   # null instead of crash
```

## `user://` on web is IndexedDB

Same code, different storage: real file on desktop
(`~/Library/Application Support/Godot/app_userdata/<project>/` on macOS),
IndexedDB in the browser. Web flushes asynchronously — a save made in the
same instant the tab closes can be lost, so save at deliberate moments.
Per-browser, wiped by "clear site data".

## `res://` paths are case-sensitive in web exports

macOS's filesystem hides casing mismatches; the web export does not. A
`load("res://Assets/foo.png")` that works locally 404s in the browser.
Match file casing exactly, always.
