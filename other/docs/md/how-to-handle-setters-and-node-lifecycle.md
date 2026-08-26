# How to handle setters and the node lifecycle

Why: a portrait configured with `sprite = "red_prince"` in a scene file
silently showed the default sprite (fixed 2026-08 in
`_rpgm_portrait.gd`). The cause is *when* setters run during
instantiation. This doc is the general rule.

## Instantiation lifecycle

When a scene containing your node is instantiated:

1. **`_init`** — script instance created. Exported vars hold their
   *code* defaults. No scene-file values yet.
2. **Property assignment** — every value stored in the `.tscn` is
   assigned, one by one, **and setters run here**. But the node is in
   limbo: not in the tree, `is_node_ready()` is false, `@onready` vars
   are nil, `%UniqueName` / `get_node()` unusable. Note: the `.tscn`
   only stores values that differ from the default — if the scene file
   says nothing, the setter never runs at all.
3. **Enter tree** — `NOTIFICATION_ENTER_TREE`, parent-first.
4. **`@onready` + `_ready`** — depth-first, children before parents;
   `@onready` vars are assigned immediately before the node's own
   `_ready`.

So a setter that touches child nodes cannot work at step 2. It can only
*store* the value.

## The idiom: store, apply-if-ready, re-apply in _ready

```gdscript
var sprite := "cream":
	set(v):
		sprite = v
		if not is_node_ready(): return   # too early to touch children
		_apply_sprite()                  # late (runtime) assignments

func _ready():
	_apply_sprite()                      # early (scene-file) assignments
```

Both paths converge on the same applied state. The bug pattern to watch
for: a setter with the `is_node_ready()` guard but **no matching
re-apply in `_ready`** — scene-file values are then silently dropped,
and only runtime assignments work.

## Best practices (checklist)

- Setters must always store the value first, then optionally apply.
  Never make storing conditional on readiness.
- Every `is_node_ready()` guard in a setter needs a matching re-apply
  in `_ready`. Grep for `is_node_ready(): return` inside `set(` blocks
  when reviewing.
- Keep getters side-effect free — the editor and debugger call them
  freely.
- Prefer failing loudly: applying a bad value (e.g. an animation name
  missing from the SpriteFrames) should error at load, not silently
  show a default.

### Additionally, for @tool scripts

The editor runs the whole script: `_ready`, `_process`, setters on
every inspector tweak, every scene save/reload — often in states where
the tree is not what runtime code expects.

- Guard game logic with `if Engine.is_editor_hint(): return` in
  `_ready`/`_process` (see `_rpgm_event.gd`). Setters generally should
  *not* be guarded this way — applying values is what makes the editor
  preview work — but they must survive weird tree states via the
  readiness guard.
- `@onready` vars and `%` lookups may be nil in editor contexts; null
  checks in editor-reachable paths (`if %_sampler == null: return`).
- Don't connect signals or spawn nodes unconditionally in `_ready` of a
  tool script — the editor calls `_ready` on every scene open/reload,
  which duplicates connections and leaks nodes. Guard with
  `is_editor_hint()` unless the editor genuinely needs it.
- Resources are shared by default: a tool script mutating a resource
  (SpriteFrames, ShaderMaterial, ...) edits it for every scene using
  it, and the editor may save that change to disk. Duplicate before
  mutating, or treat as read-only.
- `static var` state persists for the whole editor session (e.g. the
  portrait `_frame_cache`) — after re-importing art, stale entries can
  show old pixels in the editor until restart. Prefer keys that change
  with content, or accept the restart.
- `_get_property_list()` and friends are called constantly; keep them
  cheap and crash-proof (`if not is_inside_tree(): return []`).
