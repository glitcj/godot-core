# Patterns guide: composition vs inheritance vs delegation

When a node needs a capability (movement, portraits, event scripting), there
are three ways to attach it. This repo uses all three deliberately — this is
the guide for picking one.

## Rule of thumb

**Always start with composition.** A child component is the cheapest to add,
the cheapest to undo, and demands no design decision up front.

**When ~80%+ of a node family carries the same component, review it for
promotion to inheritance.** Prevalence is the trigger, not the proof — a
component earns promotion only if all of these hold:

1. **Prevalence** — all or nearly all members of the family carry it, and
   never more than one each. (A component that appears multiple times per
   host, like portraits or scripts, is disqualified outright — a base class
   can only be mixed in once.)
2. **Host-coupling** — its code is mostly `get_parent()` manipulation.
   That's the proof it was never really a component, just the host's own
   behavior in a separate node. A prevalent but self-contained component
   (every event has a portrait) stays composition.
3. **No conflict** — the single-inheritance slot is free, and no other
   capability is likely to want it more.

Promotion trigger -> confirmation -> permission: prevalence triggers the
review, host-coupling confirms it, a free inheritance slot permits it.
This is exactly the path `_RPGM_Mover` took.

## The three patterns

### 1. Composition — child component node

The capability is a node added as a child in the scene tree. The host finds
it (`find_child`, `get_portrait()`) and talks to it through its API.

```
_npc_1_1 (_RPGM_Event)
├── _RPGM_Portrait      <- component
├── _rpgm_script        <- component
└── Area2D              <- component
```

**Use when:**
- The capability is **optional per-instance** and you want to add/remove it
  by editing the scene tree, not by changing code.
- The component is **self-contained** — it does its job with its own state,
  children, and rendering, touching the host through a narrow interface.
- One host may carry **several instances** of it (an event with multiple
  portraits or scripts).

**In this repo:** `_RPGM_Portrait`, `_RPGM_Script` subclasses, `Area2D`.
A portrait renders itself; a script runs its own triggers. Neither spends
its time reaching into the parent.

### 2. Inheritance — mixin base class

The capability is a class inserted into the inheritance chain. The host *is*
the capability; vars appear natively in the inspector; logic stays delineated
in the base class's own file. This is GDScript's stand-in for traits/mixins.

```
_RPGM_Node <- _RPGM_Mover <- _RPGM_Event
                          <- _RPGM_Player
```

**Use when:**
- The capability is really **the host's own behavior** — the telltale smell
  is a "component" whose methods are mostly `get_parent()` manipulation.
- **Every** member of a node family should have it (not optional).
- All hosts share a **common ancestor type**, so one chain covers them.
- Nothing else is competing for the single-inheritance slot.

**In this repo:** `_RPGM_Mover`. It used to be an optional child node, but
~80% of its code manipulated its parent (tweening the parent's position,
setting the parent's facing, even type-switching on the parent's class).
Promoting it to a base class turned all of that into `self` and deleted the
parent/child sync code. Subclasses customise via overridable hooks
(`_on_facing_changed()`) rather than type-switches.

**The cost:** single inheritance is spent. A second mixin-shaped capability
can't be stacked alongside it — it would have to chain linearly or fall back
to one of the other two patterns. Pay this cost at most once per family, for
the capability that is most universal.

### 3. Delegation — plain logic object

The capability is a non-Node class (`RefCounted`) the host instantiates and
holds. The host owns the exported vars; the delegate holds the logic and
operates on the host through an explicit reference.

```gdscript
class_name Mover extends RefCounted
var host: Node2D
func _init(h): host = h
func move(v): # reads/writes host.map_position, tweens host.global_position

# in the host:
@export var map_position := Vector2i.ZERO
@onready var mover := Mover.new(self)
```

**Use when:**
- You want logic in its own file but the hosts have **unrelated base types**
  (e.g. a `Node2D` and a `Camera2D`), so a shared base class is impossible.
- The host needs **several** such capabilities, or you want to **swap** the
  logic at runtime (strategy pattern — e.g. different AI behaviours).
- The logic doesn't need to be a node: no scene presence, no `_process` of
  its own, no editor exports of its own.

**Caveats:** the contract is implicit (the delegate duck-types against
`host.foo`), signals/`await` live on the delegate not the host, and tree
access goes through `host.get_tree()`. It relocates coupling rather than
dissolving it — every `get_parent()` just becomes `host.`.

**In this repo:** not currently used. It was the runner-up design for the
mover refactor; it lost because all mover hosts share `_RPGM_Node`, so
inheritance could delete the host coupling instead of renaming it.

## What this repo's components should be

| Component            | Pattern     | Deciding signal                                   |
| -------------------- | ----------- | ------------------------------------------------- |
| `_RPGM_Portrait`     | Composition | Self-contained visual; several per host           |
| `_RPGM_Script`       | Composition | Optional, varies per event; several per host      |
| `Area2D` (+ shape)   | Composition | Engine node; only some events need an area        |
| `_RPGM_Mover`        | Inheritance | On ~every event/player; was pure host-coupling    |
| `_RPGM_Lambdas`      | Composition | Map-level service; one per map, self-contained    |
| `Camera2D` rig       | Composition | Self-contained; host (`_RPGM_Camera`) just moves  |

Why each one lands where it does:

- **`_RPGM_Portrait`** — the canonical composed component. It renders and
  animates itself, never modifies its host, and an event can carry several
  (one per script state). Even though nearly every event has one, prevalence
  alone doesn't promote it: it fails the host-coupling test (rule of thumb,
  gate 2) and the one-per-host requirement (gate 1).
- **`_RPGM_Script`** — composition for the same reasons, plus the whole point
  of scripts is that an event holds a *varying set* of them and toggles which
  are active. It does peek at its parent (lazy `mover`/`portrait` refs), but
  reading the host's API is normal component behavior — the smell is
  *manipulating* the host, not talking to it.
- **`Area2D`** — plain engine node, only some events need one. Nothing to
  debate.
- **`_RPGM_Mover`** — the promoted one. It sat on ~every event plus the
  player and camera, at most one each, and its methods tweened the parent's
  position, wrote the parent's facing, and type-switched on the parent's
  class. All three gates passed; it's now the mixin base
  (`_RPGM_Node <- _RPGM_Mover <- _RPGM_Event / _RPGM_Player`).
- **`_RPGM_Lambdas`** — one per map, a service the map's scripts call into.
  It orchestrates *other* nodes rather than its parent, so it has no
  inheritance case at all.
- **Camera rig** — `_RPGM_Camera` is an `_RPGM_Event` (so it inherits mover
  behavior), and the `Camera2D` under it stays a composed child: the rig
  moves, the camera renders.


## Quick decision test

Ask these in order:

1. **Is it optional per-instance, or self-contained with its own visuals or
   children?** -> Composition (child node).
2. **Is it universal to one node family, mostly made of host manipulation,
   and the inheritance slot is free?** -> Inheritance (mixin base class).
3. **Do hosts have incompatible base types, or do you need swappable /
   stacked logic?** -> Delegation (RefCounted logic object).


Default to composition when unsure — it's the cheapest to undo. Reach for
inheritance only when the "component" turns out to be the host's own
behavior, and for delegation only when the type system rules inheritance out.

If a future component starts accumulating `get_parent()` calls and shows up
on every member of a family, that's the mover story repeating — run it
through the rule of thumb.