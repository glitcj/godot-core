# Godot Player-Enemy Collision Setup

## Physics Bodies vs Area2D

| What you want | Use |
|---|---|
| Character that moves and collides with walls | CharacterBody2D |
| Physics object (barrel, crate) | RigidBody2D |
| Immovable wall/platform | StaticBody2D |
| Detect overlap, trigger zones, pickups, hitboxes | Area2D |
| Damage / combat detection | Area2D (nested in a physics body) |

`CharacterBody2D` and `RigidBody2D` are for physics simulation — movement, collision resolution, pushing and being pushed. They are not designed for game logic detection. `Area2D` is for pure detection with no physics response, exposing clean signals that are easy to hook into.

---

## The Hitbox / Hurtbox Pattern

The standard approach is to nest `Area2D` nodes inside your physics bodies as children. The `Area2D` handles all detection; the parent body handles movement.

```
Player (CharacterBody2D)
└── Hurtbox (Area2D)         ← "I can be hit"
    └── CollisionShape2D

Enemy (CharacterBody2D)
└── Hurtbox (Area2D)         ← "I can be hit"
    └── CollisionShape2D

Bullet (CharacterBody2D or Area2D)
└── Hitbox (Area2D)          ← "I deal damage"
    └── CollisionShape2D
```

The **Hitbox detects Hurtboxes** — not bodies detecting bodies. The `CharacterBody2D` itself has no `body_entered` signal; only `Area2D` does.

---

## Collision Layer Setup

```
Layer 1 — world / walls
Layer 2 — player body
Layer 3 — enemy body
Layer 4 — player hurtbox
Layer 5 — enemy hurtbox
```

```gdscript
# Player CharacterBody2D
collision_layer = 0b00010   # layer 2
collision_mask  = 0b00001   # scans layer 1 (walls)

# Player Hurtbox (Area2D) — passive
collision_layer = 0b01000   # layer 4
collision_mask  = 0          # scans nothing

# Enemy Hurtbox (Area2D) — passive
collision_layer = 0b10000   # layer 5
collision_mask  = 0          # scans nothing

# Bullet Hitbox (Area2D) — active scanner
collision_layer = 0
collision_mask  = 0b11000   # scans layers 4 + 5
```

---

## How Area2D Detection Actually Works

Only the **scanning side** needs to include the target in its mask. The target just needs to be on the right layer and have `monitorable = true`.

```gdscript
# Hitbox — active
monitoring   = true
collision_mask = 0b10000    # must include the hurtbox layer

# Hurtbox — passive
monitorable    = true
collision_layer = 0b10000   # must match what the hitbox scans
collision_mask  = 0          # does not need to scan anything
```

Only the Hitbox receives the `area_entered` signal. The Hurtbox is never notified — it just exposes itself to be found.

---

## Signal Flow and Damage Logic

Use `area_entered` (not `body_entered`) when a Hitbox overlaps a Hurtbox.

```gdscript
# On the Bullet's Hitbox Area2D:
func _on_area_entered(area: Area2D) -> void:
    if area.get_parent().has_method("take_damage"):
        area.get_parent().take_damage(damage)
```

```gdscript
# On Enemy CharacterBody2D:
func take_damage(amount: int) -> void:
    health -= amount
```

---

## Key Takeaways

- **CharacterBody2D / RigidBody2D** handle movement and physics — not game logic detection.
- **Area2D** handles detection — no physics response, just clean signals.
- Use **Hitbox/Hurtbox** (nested Area2Ds) for combat, not body-to-body collision.
- Hurtboxes are **passive** (`mask = 0`), Hitboxes are the **active scanners**.
- Only the scanner's mask needs to include the target's layer — detection is one-directional.
- Use `area_entered` for Hitbox/Hurtbox interaction, `body_entered` for detecting physics bodies directly.
